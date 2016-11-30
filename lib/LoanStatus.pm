package LoanStatus;

@ISA         = qw(Exporter);
@EXPORT      = qw(loan_status_app);
@EXPORT_OK   = qw();

$VERSION = '1.0';

use Modern::Perl;
use XML::DOM;

use C4::Context;
use IdMapping;
use Data::Dumper;
use utf8;

sub _fail {
	my $msg = shift;
	warn "LoanStatus: $msg";
	return ['502', [], [ ] ];
}

sub loan_status_app {
	my $env = shift;

	my $context = new C4::Context;

	my $idmapping = new IdMapping( { context => $context });

	my $row;

	eval {
           $row = $idmapping->get_biblioitem( 'libris_bibid' => $env->{'libris_bibid'},
                                              'libris_99'      => $env->{'libris_99'},
                                              'isbn'           => $env->{'isbn'},
                                              'issn'           => $env->{'issn'} );
        };

	if ($@) {
		_fail($@);
	}

	unless (defined($row) && defined($row->{biblioitemnumber})) {
		return ['404', [], [] ];
    }

	my $biblioitemnumber = $row->{biblioitemnumber};

	my $doc = new XML::DOM::Document();

	$doc->setXMLDecl( $doc->createXMLDecl( "1.0", "iso-8859-1", 1 ) );

	my $item_info = $doc->createElement( 'Item_Information' );
	$item_info->setAttribute( 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance' );
	$item_info->setAttribute( 'xsi:noNamespaceSchemaLocation', 'http://appl.libris.kb.se/LIBRISItem.xsd' );

	$doc->appendChild( $item_info );

	my $q = <<'EOF';
SELECT DISTINCT items.itemnumber,
                items.biblionumber,
                itemcallnumber,
				ccode_values.lib_opac       AS ccode_lib_opac,
				ccode_values.lib            AS ccode_lib,
				loc_values.lib_opac         AS loc_lib_opac,
				loc_values.lib              AS loc_lib,
				notloan_values.lib_opac     AS notloan_lib_opac,
				notloan_values.lib          AS notloan_lib,
				damaged_values.lib_opac     AS damaged_lib_opac,
				damaged_values.lib          AS damaged_lib,
				lost_values.lib_opac        AS lost_lib_opac,
				lost_values.lib             AS lost_lib,
	            itemlost_on,
                issues.date_due,
	            description,
				(SELECT COUNT(itemnumber) FROM hold_fill_targets WHERE hold_fill_targets.itemnumber = items.itemnumber) +
                (SELECT COUNT(reserve_id) FROM reserves          WHERE reserves.itemnumber          = items.itemnumber) +
				(SELECT COUNT(itemnumber) FROM tmp_holdsqueue    WHERE tmp_holdsqueue.itemnumber    = items.itemnumber) AS n_reservations
FROM items
     LEFT OUTER JOIN authorised_values AS ccode_values   ON ccode_values.authorised_value=ccode        AND ccode_values.category   = 'CCODE'
     LEFT OUTER JOIN authorised_values AS loc_values     ON loc_values.authorised_value=location       AND loc_values.category     = 'LOC'
	 LEFT OUTER JOIN authorised_values AS notloan_values ON notloan_values.authorised_value=notforloan AND notloan_values.category = 'NOT_LOAN'
	 LEFT OUTER JOIN authorised_values AS damaged_values ON damaged_values.authorised_value=damaged    AND damaged_values.category = 'DAMAGED'
	 LEFT OUTER JOIN authorised_values AS lost_values    ON lost_values.authorised_value=itemlost      AND lost_values.category    = 'LOST'
     LEFT OUTER JOIN issues     ON items.itemnumber=issues.itemnumber
     LEFT OUTER JOIN reserves   ON items.itemnumber=reserves.itemnumber
     LEFT OUTER JOIN itemtypes  ON itype=itemtypes.itemtype
WHERE items.biblioitemnumber = ?;
EOF

	my $sth = $context->dbh->prepare($q);
	my $rv = $sth->execute( $biblioitemnumber ) or _fail( 'Query failed.' );

	my $count = 1;

	while (my $row = $sth->fetchrow_hashref) {

		my $item = $doc->createElement( 'Item' );

		my $add = sub {
			my ($tag, $content) = @_;
			my $element = $doc->createElement( $tag );
			my $text = $doc->createTextNode( $content );
			$element->appendChild($text);
			$item->appendChild( $element );
			return $item;
		};

		my $authval = sub {
			my $name = shift;
			if (defined($row->{"${name}_lib_opac"})) {
				return $row->{"${name}_lib_opac"};
			}
			return $row->{"${name}_lib"};
		};

		$add->( 'Item_No', $count++ );
		$add->( 'Call_No', $row->{itemcallnumber} );
		$add->( 'Location', $authval->('loc') );
		$add->( 'UniqueItemId', $row->{itemnumber} );
		$add->( 'Loan_Policy', $row->{description} );

		my $reserved = $row->{n_reservations} > 0 ? ' reserverad med ' . $row->{n_reservations} . ' på kö.' : '';

		my $status = sub {
			if (defined($row->{'date_due'})) {
				return ("Utlånad$reserved",
						"Åter: ",
						substr($row->{'date_due'}, 0, 10));
			}
			my $notloan = $authval->('notloan');
			if (defined($notloan)) {
				return ($notloan, '', '');
			}
			my $lost = $authval->('lost');
			if (defined($lost)) {
				return ($lost, defined($row->{'itemlost_on'}) ? ('Förlorad den: ', substr($row->{'itemlost_on'}, 0, 10))  : ('', ''));
			}
			my $damaged = $authval->('damaged');
			if (defined($damaged)) {
				return ($damaged, '', '');
			}
			if (defined($row->{'n_reservations'}) && $row->{'n_reservations'} > 0) {
				return ($reserved, '', '');
			}
			return ('Tillgänglig', '', '');
		};

		my ($s, $sdd, $sd) = $status->();

		$add->( 'Status', $s );
		$add->( 'Status_Date_Description', $sdd );
		$add->( 'Status_Date', $sd );

		$item_info->appendChild( $item );
	}


	return  [
          '200',
          [ 'Content-Type' => 'application/xml' ],
          [ $doc->toString() ], # or IO::Handle-like object
      ];
}

1;

=head1 NAME

LoanStatus - Fetch information of the loan status of Koha items

=head1 SYNOPSIS


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
