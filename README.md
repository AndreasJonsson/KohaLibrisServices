
Loan status for Libris integration of Koha
==========================================

Installation
------------

   perl Makefile.PL
   make
   make test
   make install


Usage
-----

Add to plack.psgi.

   use KohaLibrisServices;
   use Plack::Middleware::SetEnvFromQueryString;

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

