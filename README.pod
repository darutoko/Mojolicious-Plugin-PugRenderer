package Mojolicious::Plugin::PugRenderer;
use Mojo::Base 'Mojolicious::Plugin';
use Template::Pug;
use Mojo::Util qw|monkey_patch|;

our $VERSION = '0.01';

sub register {
	my ($self, $app, $conf) = @_;

	my $settings = {
		cached => 1,
		namespace => 'Template::Pug::SandBox',
		%{$conf->{template} || {}},
	};
	$settings->{prepend} = 'my $self = my $c = _C;' . ($settings->{prepend} // '');
	my $tp = Template::Pug->new($settings);

	$app->renderer->default_handler('pug')->add_handler($conf->{name} || 'pug' => sub {
		my ($renderer, $c, $output, $options) = @_;

		my $inline = $options->{inline};
		my $name = $inline // $renderer->template_name($options);
		return unless defined $name;

		# Extract variables from stash
		my $variables = { map { $_ => $c->stash->{$_} } grep /^\w+$/, keys %{$c->stash} };

		# Export helpers only once
		unless ($self->{helpers}) {
			$self->{helpers} = 1;
			for my $method (grep {/^\w+$/} keys %{$renderer->helpers}) {
				my $sub = $renderer->helpers->{$method};
				# monkey_patch $class, $method, sub { $class->_C->$sub(@_) };
				monkey_patch $settings->{namespace}, $method, sub { $settings->{namespace}->_C->$sub(@_) };
			}

		}
		
		no strict 'refs';
		no warnings 'redefine';
		local *{$settings->{namespace} .'::_C'} = sub {$c};

		# Inline
		if (defined $inline) {
			$c->app->log->debug("Rendering inline template");
			$$output = $tp->render($inline, $variables);

		# File
		} else {

			# File path
			if (defined(my $path = $renderer->template_path($options))){
				$c->app->log->debug("Rendering template '$name'");
				$$output = $tp->render_file($path, $variables);

			# DATA section
			} elsif (defined(my $data = $renderer->get_data_template($options))) {
				$c->app->log->debug("Rendering template '$name' from DATA section");
				$$output = $tp->render($data, $variables);

			} else {
				$c->app->log->debug("Template '$name' not found");
			}

		}
	});
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::PugRenderer - Template::Pug renderer plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('PugRenderer');
  $self->plugin(PugRenderer => {name => 'foo'});
  $self->plugin(PugRenderer => {name => 'bar', template => {basedir => 'templates'}});

  # Mojolicious::Lite
  plugin 'PugRenderer';
  plugin PugRenderer => {name => 'foo'};
  plugin PugRenderer => {name => 'bar', template => {basedir => 'templates'}};

=head1 DESCRIPTION

L<Mojolicious::Plugin::PugRenderer> is a renderer for L<Template::Pug> templates.

=head1 OPTIONS

L<Mojolicious::Plugin::PugRenderer> supports the following options.

=head2 name

	# Mojolicious::Lite
	plugin PugRenderer => {name => 'foo'};

Handler name, defaults to C<pug>.

=head2 template

	# Mojolicious::Lite
	plugin PugRenderer => {template => {basedir => 'templates'}};

Attribute values passed to L<Template::Pug> object used to render templates.


=head1 METHODS

L<Mojolicious::Plugin::PugRenderer> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
