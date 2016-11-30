package IsbnRegexp;

@ISA         = qw(Exporter);
@EXPORT      = qw(isbn_regexp);
@EXPORT_OK   = qw();

$VERSION = '1.0';

sub isbn_regexp {
    my $isbn = shift;
    $isbn =~ /([-\d]+)/;
    $isbn = $1;

    $isbn =~ s/-//g;

    if (length($isbn) < 10) {
        return undef;
    }

    my $re = '';
    for (my $i = 0; $i < length($isbn); $i++) {
        my $c = substr($isbn, $i, 1);
        $re .= $c;
        if ($i < length($isbn) - 1) {
            $re .= '-?';
        }
    }

    return '[[:<:]]' . $re . '[[:>:]]';
}
