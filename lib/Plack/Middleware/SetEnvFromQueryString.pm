package Plack::Middleware::SetEnvFromQueryString;

use Modern::Perl;
use parent 'Plack::Middleware';
use URI::Query;

use Data::Dumper;

sub call {
    my ($self, $env) = @_;

    my %qq = URI::Query->new($env->{QUERY_STRING})->hash();

    for my $param (@{$self->{query_parameters}}) {
        if (defined($qq{$param})) {
            $env->{$param} = $qq{$param};
        }
    }
    return $self->app->($env);
}

1;
__END__

=head1 NAME

Plack::Middleware::SetEnvFromQueryParameters - Populate plack
application environment with values from query string.

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
