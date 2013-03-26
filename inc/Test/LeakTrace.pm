#line 1
package Test::LeakTrace;

use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.14';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use Test::Builder::Module;
our @ISA = qw(Test::Builder::Module);

use Exporter qw(import); # use Exporter::import for backward compatibility
our @EXPORT = qw(
    leaktrace leaked_refs leaked_info leaked_count
    no_leaks_ok leaks_cmp_ok
    count_sv
);

our %EXPORT_TAGS = (
    all  => \@EXPORT,
    test => [qw(no_leaks_ok leaks_cmp_ok)],
    util => [qw(leaktrace leaked_refs leaked_info leaked_count count_sv)],
);


sub _do_leaktrace{
    my($block, $name, $need_stateinfo, $mode) = @_;

    if(!defined($mode) && !defined wantarray){
        warnings::warnif void => "Useless use of $name() in void context";
    }

    if($name eq 'leaked_count') {
        my $start;
        $start = count_sv();
        $block->();
        return count_sv() - $start;
    }

    local $SIG{__DIE__} = 'DEFAULT';

    _start($need_stateinfo);
    eval{
        $block->();
    };
    if($@){
        _finish(-silent);
        die $@;
    }

    return _finish($mode);
}

sub leaked_refs(&){
    my($block) = @_;
    return _do_leaktrace($block, 'leaked_refs', 0);
}

sub leaked_info(&){
    my($block) = @_;
    return _do_leaktrace($block, 'leaked_refs', 1);
}

sub leaked_count(&){
    my($block) = @_;
    return scalar _do_leaktrace($block, 'leaked_count', 0);
}

sub leaktrace(&;$){
    my($block, $mode) = @_;
    _do_leaktrace($block, 'leaktrace', 1, defined($mode) ? $mode : -simple);
    return;
}


sub leaks_cmp_ok(&$$;$){
    my($block, $cmp_op, $expected, $description) = @_;

    my $Test = __PACKAGE__->builder;

    if(!_runops_installed()){
        my $mod = exists $INC{'Devel/Cover.pm'} ? 'Devel::Cover' : 'strange runops routines';
        return $Test->ok(1, "skipped (under $mod)");
    }

    # calls to prepare cache in $block
    $block->();

    my $got = _do_leaktrace($block, 'leaked_count', 0);

    my $desc = sprintf 'leaks %s %-2s %s', $got, $cmp_op, $expected;
    if(defined $description){
        $description .= " ($desc)";
    }
    else{
        $description = $desc;
    }

    my $result = $Test->cmp_ok($got, $cmp_op, $expected, $description);

    if(!$result){
        open local(*STDERR), '>', \(my $content = '');
        $block->(); # calls it again because opening *STDERR changes the run-time environment

        _do_leaktrace($block, 'leaktrace', 1, -verbose);
        $Test->diag($content);
    }

    return $result;
}

sub no_leaks_ok(&;$){
    # ($block, $description)
    splice @_, 1, 0, ('<=', 0); # ($block, '<=', 0, $description);
    goto &leaks_cmp_ok;
}


1;
__END__

#line 339
