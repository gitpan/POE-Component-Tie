use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'POE::Component::Tie',
    VERSION_FROM      => 'lib/POE/Component/Tie.pm',
    PREREQ_PM         => {POE},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/POE/Component/Tie.pm',
       AUTHOR         => 'Larry Shatzer, Jr. <larrysh@cpan.org>') : ()),
);
