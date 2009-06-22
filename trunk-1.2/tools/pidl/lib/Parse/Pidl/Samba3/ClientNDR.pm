###################################################
# Samba3 client generator for IDL structures
# on top of Samba4 style NDR functions
# Copyright jelmer@samba.org 2005-2006
# released under the GNU GPL

package Parse::Pidl::Samba3::ClientNDR;

use Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(GenerateFunctionInEnv ParseFunction $res $res_hdr);

use strict;
use Parse::Pidl qw(fatal warning);
use Parse::Pidl::Typelist qw(hasType getType mapTypeName scalar_is_reference);
use Parse::Pidl::Util qw(has_property is_constant ParseExpr);
use Parse::Pidl::NDR qw(GetPrevLevel GetNextLevel ContainsDeferred);
use Parse::Pidl::Samba4 qw(DeclLong);
use Parse::Pidl::Samba4::NDR::Parser qw(GenerateFunctionInEnv);

use vars qw($VERSION);
$VERSION = '0.01';

sub indent($) { my ($self) = @_; $self->{tabs}.="\t"; }
sub deindent($) { my ($self) = @_; $self->{tabs} = substr($self->{tabs}, 1); }
sub pidl($$) { my ($self,$txt) = @_; $self->{res} .= "$self->{tabs}$txt\n"; }
sub pidl_hdr($$) { my ($self, $txt) = @_; $self->{res_hdr} .= "$txt\n"; } 
sub fn_declare($$) { my ($self,$n) = @_; $self->pidl($n); $self->pidl_hdr("$n;"); }

sub new($)
{
	my ($class) = shift;
	my $self = { res => "", res_hdr => "", tabs => "" };
	bless($self, $class);
}

sub ParseFunction($$$)
{
	my ($self, $if, $fn) = @_;

	my $inargs = "";
	my $defargs = "";
	my $uif = uc($if);
	my $ufn = "NDR_".uc($fn->{NAME});

	foreach (@{$fn->{ELEMENTS}}) {
		$defargs .= ", " . DeclLong($_);
	}
	$self->fn_declare("NTSTATUS rpccli_$fn->{NAME}(struct rpc_pipe_client *cli, TALLOC_CTX *mem_ctx$defargs)");
	$self->pidl("{");
	$self->indent;
	$self->pidl("struct $fn->{NAME} r;");
	$self->pidl("NTSTATUS status;");
	$self->pidl("");
	$self->pidl("/* In parameters */");

	foreach (@{$fn->{ELEMENTS}}) {
		if (grep(/in/, @{$_->{DIRECTION}})) {
			$self->pidl("r.in.$_->{NAME} = $_->{NAME};");
		} 
	}

	$self->pidl("");
	$self->pidl("if (DEBUGLEVEL >= 10)");
	$self->pidl("\tNDR_PRINT_IN_DEBUG($fn->{NAME}, &r);");
	$self->pidl("");
	$self->pidl("status = cli_do_rpc_ndr(cli, mem_ctx, PI_$uif, &ndr_table_$if, $ufn, &r);");
	$self->pidl("");

	$self->pidl("if (!NT_STATUS_IS_OK(status)) {");
	$self->indent;
	$self->pidl("return status;");
	$self->deindent;
	$self->pidl("}");

	$self->pidl("");
	$self->pidl("if (DEBUGLEVEL >= 10)");
	$self->pidl("\tNDR_PRINT_OUT_DEBUG($fn->{NAME}, &r);");
	$self->pidl("");
	$self->pidl("if (NT_STATUS_IS_ERR(status)) {");
	$self->pidl("\treturn status;");
	$self->pidl("}");
	$self->pidl("");
	$self->pidl("/* Return variables */");
	foreach my $e (@{$fn->{ELEMENTS}}) {
		next unless (grep(/out/, @{$e->{DIRECTION}}));
		my $level = 0;

		fatal($e->{ORIGINAL}, "[out] argument is not a pointer or array") if ($e->{LEVELS}[0]->{TYPE} ne "POINTER" and $e->{LEVELS}[0]->{TYPE} ne "ARRAY");

		if ($e->{LEVELS}[0]->{TYPE} eq "POINTER") {
			$level = 1;
			if ($e->{LEVELS}[0]->{POINTER_TYPE} ne "ref") {
				$self->pidl("if ($e->{NAME} && r.out.$e->{NAME}) {");
				$self->indent;
			}
		}

		if ($e->{LEVELS}[$level]->{TYPE} eq "ARRAY") {
			# This is a call to GenerateFunctionInEnv intentionally. 
			# Since the data is being copied into a user-provided data 
			# structure, the user should be able to know the size beforehand 
			# to allocate a structure of the right size.
			my $env = GenerateFunctionInEnv($fn, "r.");
			my $size_is = ParseExpr($e->{LEVELS}[$level]->{SIZE_IS}, $env, $e->{ORIGINAL});
			$self->pidl("memcpy($e->{NAME}, r.out.$e->{NAME}, $size_is);");
		} else {
			$self->pidl("*$e->{NAME} = *r.out.$e->{NAME};");
		}

		if ($e->{LEVELS}[0]->{TYPE} eq "POINTER") {
			if ($e->{LEVELS}[0]->{POINTER_TYPE} ne "ref") {
				$self->deindent;
				$self->pidl("}");
			}
		}
	}

	$self->pidl("");
	$self->pidl("/* Return result */");
	if (not $fn->{RETURN_TYPE}) {
		$self->pidl("return NT_STATUS_OK;");
	} elsif ($fn->{RETURN_TYPE} eq "NTSTATUS") {
		$self->pidl("return r.out.result;");
	} elsif ($fn->{RETURN_TYPE} eq "WERROR") {
		$self->pidl("return werror_to_ntstatus(r.out.result);");
	} else {
		warning($fn->{ORIGINAL}, "Unable to convert $fn->{RETURN_TYPE} to NTSTATUS");
		$self->pidl("return NT_STATUS_OK;");
	}

	$self->deindent;
	$self->pidl("}");
	$self->pidl("");
}

sub ParseInterface($$)
{
	my ($self, $if) = @_;

	my $uif = uc($if->{NAME});

	$self->pidl_hdr("#ifndef __CLI_$uif\__");
	$self->pidl_hdr("#define __CLI_$uif\__");
	$self->ParseFunction($if->{NAME}, $_) foreach (@{$if->{FUNCTIONS}});
	$self->pidl_hdr("#endif /* __CLI_$uif\__ */");
}

sub Parse($$$$)
{
	my($self,$ndr,$header,$ndr_header) = @_;

	$self->pidl("/*");
	$self->pidl(" * Unix SMB/CIFS implementation.");
	$self->pidl(" * client auto-generated by pidl. DO NOT MODIFY!");
	$self->pidl(" */");
	$self->pidl("");
	$self->pidl("#include \"includes.h\"");
	$self->pidl("#include \"$header\"");
	$self->pidl_hdr("#include \"$ndr_header\"");
	$self->pidl("");
	
	foreach (@$ndr) {
		$self->ParseInterface($_) if ($_->{TYPE} eq "INTERFACE");
	}

	return ($self->{res}, $self->{res_hdr});
}

1;
