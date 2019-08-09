
Loan status and other services for Libris integration of Koha
==========================================

This module contains three plack applications for Libris integration.

* loan_status_app
* redirect_bibitem_app
* redirect_reserve_app

These applications need to be adapted depending on the bibliographic framework.

Installation
------------

    perl Makefile.PL
    make
    make test
    make install

Database table
--------------

Before using the table used in IdMap.pm needs to be created.

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


Usage
-----

Add to plack.psgi.

    use KohaLibrisServices;
    use Plack::Middleware::SetEnvFromQueryString;

    use RedirectBibitem;
    use RedirectReserve;
    use LoanStatus;

    my $redirect_bibitem = Plack::Middleware::SetEnvFromQueryString->wrap(\&redirect_bibitem_app, 'query_parameters' => [ 'libris_bibid', 'libris_99', 'isbn' ]);
    my $redirect_reserve = Plack::Middleware::SetEnvFromQueryString->wrap(\&redirect_reserve_app, 'query_parameters' => [ 'libris_bibid', 'libris_99', 'isbn' ]);
    my $loan_status      = Plack::Middleware::SetEnvFromQueryString->wrap(\&loan_status_app,      'query_parameters' => [ 'libris_bibid', 'libris_99', 'isbn' ]);

    builder {

       .
       .
       .

        mount '/redirect-bibitem' => $redirect_bibitem;
        mount '/loan-status'      => $loan_status;
        mount '/redirect-reserve' => $redirect_reserve;
    }

