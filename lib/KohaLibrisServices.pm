package KohaLibrisServices;

use 5.020002;
use strict;
use warnings;

require Exporter;
require RedirectBibitem;
require RedirectReserve;
require LoanStatus;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use KohaLibrisServices ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	redirect_bibitem_app
        redirect_reserve_app
        loan_status_app
);

our $VERSION = '0.01';


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

KohaLibrisServices - Perl extension for blah blah blah

=head1 SYNOPSIS

  use KohaLibrisServices;


=head1 DESCRIPTION

=head2 EXPORT


	redirect_bibitem_app
        redirect_reserve_app
        loan_status_app

=head1 AUTHOR

Andreas Jonsson, E<lt>aj@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Andreas Jonsson

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
