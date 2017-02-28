package RedirectBibitem;

@ISA         = qw(Exporter);
@EXPORT      = qw(redirect_bibitem_app);
@EXPORT_OK   = qw();

use Modern::Perl;

use C4::Context;
use IdMapping;
use URI::Escape;

sub redirect_bibitem_app {
	my $env = shift;

	my $context = new C4::Context;

	my $idmapping = new IdMapping( { context => $context });

	my $row;
	my $ret = eval {
         $row = $idmapping->get_biblioitem( 'libris_bibid'   => $env->{'libris_bibid'},
					    'isbn'           => $env->{'isbn'},
                                            'issn'           => $env->{'issn'} );
	};

	my $loc;
	my $code;

	if ($@) {
		warn "RedirectBibitem: $@\n";
		$loc = '/cgi-bin/koha/errors/500.pl';
		$code = '303';
    } elsif (defined($row) && defined($row->{biblionumber})) {
		$loc = '/cgi-bin/koha/opac-detail.pl?biblionumber=' . uri_escape($row->{biblionumber});
		$code = '301';
	} else {
		$code = '303';
		$loc = '/cgi-bin/koha/errors/404.pl';
	}

	return  [
          $code,
          [ 'Location' => $loc ],
          [  ],
      ];

}

1;

=head1 NAME

RedirectBibitem - Redirect to bibliographic item given Libris id number or ISBN.

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
