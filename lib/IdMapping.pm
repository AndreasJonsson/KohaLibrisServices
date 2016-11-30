package IdMapping;

use Moose;
use Carp;
use Data::Dumper;
use IsbnRegexp;
use Clone qw(clone);

has 'context' => (
    is => 'ro',
    isa => 'C4::Context'
    );

__PACKAGE__->meta->make_immutable;

sub _add {
    my ($w, $par, $pend_w, $pend_end, $where, $pending, $params_in, $params_out) = @_;

    if (defined($params_in->{$par}) && $params_in->{$par} ne '') {

        if (defined($$pending)) {
            $$where .= $$pending;
            $$pending = undef;
        }

        $$where .= $w;
        push @$params_out, $params_in->{$par};


        if (defined($pend_w)) {
            $$pending = $pend_w;
        }

    }
    delete($params_in->{$par});
}

sub get_biblioitem {
    my ($self, %params) = @_;

    %params = %{ clone(\%params) };

    if (defined($params{isbn})) {
        $params{isbn} = isbn_regexp($params{isbn});
    }

    my %params_clone = %{ clone(\%params) };

    my $where = '';
    my @params = ();
    my $pending;

    my $add = sub {
        my ($w, $par, $pend_w) = @_;
        _add ($w, $par, $pend_w,  \%params, \$where, \$pending, \%params, \@params);
    };

    $add->('kidm_bibid = ?', 'libris_bibid', ' OR ISNULL(kidm_bibid) AND ');
    $add->('kidm_99 = ?', 'libris_99', ' OR ISNULL(kidm_99) AND ');
    $add->("isbn REGEXP ?", 'isbn', ' OR ISNULL(isbn) AND ');
    $add->("issn LIKE CONCAT(?, '\%')", 'issn', ' OR ISNULL(issn) AND ');

    if (+keys(%params) > 0) {
        croak("Unknown parameters: " . join(", ", keys %params));
    }

    if (+@params == 0) {
        croak("No parameters given!");
    }

    my $row = $self->do_query($where, @params);

    if (!defined($row)) {
        $row = $self->do_query_slow( %params_clone );
    }

    return $row;
}

sub do_query {
    my ($self, $where, @params) = @_;

    my $q = <<"EOF";
SELECT biblionumber, biblioitems.biblioitemnumber, kidm_bibid, kidm_99, isbn, issn FROM
    kreablo_idmapping JOIN biblioitems USING(biblioitemnumber) JOIN biblio USING(biblionumber)
WHERE
    $where;
EOF

    my $sth = $self->context->dbh->prepare($q);
    my $rv = $sth->execute(@params) or croak "Query failed.";

    if ($sth->rows == 0) {
        return undef;
    } else {
        if ($sth->rows > 1) {
            carp("More than one 1 line mathed.  Query: $q params: " . join(", ", @params));
        }
    }

    return $sth->fetchrow_hashref;
}

sub do_query_slow {
    my ($self, %params) = @_;

    my $libris_bibid = $params{libris_bibid};
    my $libris_99    = $params{libris_99};

    my $where = '';
    my @params = ();
    my $pending;

    my $add = sub {
        my ($w, $par, $pend_w) = @_;
        _add ($w, $par, $pend_w, \%params, \$where, \$pending, \%params, \@params);
    };

    $add->("isbn REGEXP ?", 'isbn', ' OR ISNULL(isbn) AND ');
    $add->('issn = ?', 'issn', ' OR ISNULL(issn) AND ');
    $add->("(ExtractValue(marcxml, '//controlfield[\@tag=\"003\"]') REGEXP '((libr)|(arkm))') AND ExtractValue(marcxml, '//controlfield[\@tag=\"001\"]') = ?", 'libris_bibid', ' OR ');
    $add->("(ExtractValue(marcxml, '//controlfield[\@tag=\"003\"]') REGEXP '((libr)|(arkm))') AND ExtractValue(marcxml, '//controlfield[\@tag=\"001\"]') = ?", 'libris_99', ' OR ');

    my $q = <<"EOF";
SELECT biblionumber, biblioitems.biblioitemnumber, isbn, issn, ExtractValue(marcxml, '//controlfield[\@tag=\"001\"]') as controlnumber, ExtractValue(marcxml, '//controlfield[\@tag=\"003\"]') as idtype
FROM
  biblioitems JOIN biblio USING (biblionumber)
WHERE
  $where;
EOF


    my $sth = $self->context->dbh->prepare($q);
    my $rv = $sth->execute( @params ) or croak "Query failed!";

    if ($sth->rows == 0) {

        return undef;
    } else {
        if ($sth->rows > 1) {
            carp("More than one 1 line mathed.  Query: $q params: " . join(", ", @params));
        }
    }

    my $row = $sth->fetchrow_hashref;

    my @cols = ();
    my @vals = ();

    my $result = {};

    my $ins = sub {
        my ($col, $val) = @_;
        if (defined($val) && $val ne '') {
            push @cols, $col;
            push @vals, $val;
            $result->{$col} = $val;
        }
    };

    my $skip = 0;

    if (defined($libris_bibid) && $libris_bibid ne '' && $libris_bibid eq $row->{controlnumber}) {
        $ins->( 'kidm_bibid', $row->{controlnumber} );
    } elsif (defined($libris_99) && $libris_99 ne '' && $libris_99 eq $row->{controlnumber}) {
        $ins->( 'kidm_99', $row->{controlnumber});
    } else {
        $skip = 1;
    }
    $ins->( 'biblioitemnumber', $row->{biblioitemnumber} );
    $result->{biblionumber} = $row->{biblionumber};

    unless ($skip) {
        my $insert = "INSERT INTO `kreablo_idmapping` (";
        $insert .= join(", ", @cols);
        $insert .= ") VALUES (";
        my @foo = map {'?'} @vals;
        $insert .= join(", ", @foo);
        $insert .=  ");";
        $sth = $self->context->dbh->prepare($insert);
        $rv = $sth->execute( @vals ) or croak "Failed to insert values!";
    }

    return $result;
}

sub create_table {
    my $self = shift;
    $self->context->dbh->do(<<"EOF");
CREATE TABLE `kreablo_idmapping` (
    `idmap` int NOT NULL AUTO_INCREMENT,
    `biblioitemnumber` int(11) NOT NULL,
    `kidm_bibid` mediumtext COLLATE utf8_unicode_ci,
    `kidm_99` mediumtext COLLATE utf8_unicode_ci,
    PRIMARY KEY (`idmap`),
    KEY `kidm_bibid` (`kidm_bibid`(255)),
    KEY `kidm_99` (`kidm_99`(255)),
   FOREIGN KEY (`biblioitemnumber`) REFERENCES `biblioitems` (`biblioitemnumber`) ON DELETE CASCADE ON UPDATE CASCADE
   );
EOF
}

no Moose;

1;

=head1 NAME

IdMapping - Maintain a table for mapping Libris identifiers to Koha identifiers.

=head1 SYNOPSIS

my $context = new C4::Context;
my $idmapping = new IdMapping({ context => $context });

my $row = $idmapping->get_biblioitem( 'libris_bibid'   => $env->{'libris_bibid'},
                                      'libris_99'      => $env->{'libris_99'},
				      'isbn'           => $env->{'isbn'},
				      'issn'           => $env->{'issn'} );


=head1 AUTHOR

Andreas Jonsson, Kreablo AB  <andreas.jonsson@kreablo.se>

=head1 LICENCE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
