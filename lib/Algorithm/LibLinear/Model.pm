package Algorithm::LibLinear::Model;

use 5.014;
use Algorithm::LibLinear;  # For Algorithm::LibLinear::Model::Raw
use Algorithm::LibLinear::Types;
use Carp qw//;
use Smart::Args;

sub new {
    args
        my $class => 'ClassName',
        my $raw_model => 'Algorithm::LibLinear::Model::Raw';

    bless +{ raw_model => $raw_model, } => $class;
}

sub load {
    args
        my $class => 'ClassName',
        my $filename => 'Str';

    my $raw_model = Algorithm::LibLinear::Model::Raw->load($filename);
    $class->new(raw_model => $raw_model);
}

sub class_labels { $_[0]->raw_model->class_labels }

sub is_probability_model { $_[0]->raw_model->is_probability_model }

sub num_classes { $_[0]->raw_model->num_classes }

sub num_features { $_[0]->raw_model->num_features }

sub raw_model { $_[0]->{raw_model} }

sub predict {
    args
        my $self,
        my $feature => 'Algorithm::LibLinear::Feature';

    $self->raw_model->predict($feature);
}

sub predict_probability {
    args
        my $self,
        my $feature => 'Algorithm::LibLinear::Feature';

    unless ($self->is_probability_model) {
        Carp::carp(
            'This method only makes sense when the model is configured for'
                . ' classification based on logistic regression.'
        );
    }
    $self->raw_model->predict_probability($feature);
}

sub predict_values {
    args
        my $self,
        my $feature => 'Algorithm::LibLinear::Feature';

    $self->raw_model->predict_values($feature);
}

sub save {
    args
        my $self,
        my $filename => 'Str';

    $_[0]->raw_model->save($filename);
}

1;

__DATA__

=head1 NAME

Algorithm::LibLinear::Model

=head1 SYNOPSIS

  use Algorithm::LibLinear;
  
  my $data_set = Algorithm::LibLinear::DataSet->load(fh => \*DATA);
  my $classifier = Algorithm::LibLinear->new->train(data_set => $data_set);
  my $classifier = Algorithm::LibLinear::Model->load(filename => 'trained.model');
  
  my @labels = $classifier->class_labels;
  $classifier->is_probability_model;
  say $classifier->num_classes;  # == @labels
  say $classifier->num_features;  # == $data_set->size
  my $class_label = $classifier->predict(feature => +{ 1 => 1, 2 => 1, ... });
  my @probabilities = $classifier->predict_probability(feature => +{ 1 => 1, 2 => 1, ... });
  my @values = $classifier->predict_values(feature => +{ 1 => 1, 2 => 1, ... });
  $classifier->save(filenmae => 'trained.model');
  
  __DATA__
  +1 1:0.708333 2:1 3:1 4:-0.320755 5:-0.105023 6:-1 7:1 8:-0.419847 9:-1 10:-0.225806 12:1 13:-1 
  -1 1:0.583333 2:-1 3:0.333333 4:-0.603774 5:1 6:-1 7:1 8:0.358779 9:-1 10:-0.483871 12:-1 13:1 
  +1 1:0.166667 2:1 3:-0.333333 4:-0.433962 5:-0.383562 6:-1 7:-1 8:0.0687023 9:-1 10:-0.903226 11:-1 12:-1 13:1 
  ...

=head1 DESCRIPTION

This class represents a classifier or an estimated function generated as a return value of L<Algorithm::LibLinear>'s C<train> method. 

If you have model files generated by LIBLINEAR's C<train> command or this class's C<save> method, you can C<load> them.

=head1 METHOD

Note that the constructor of this class is B<not> a part of public API. You can get a instance via C<<Algorithm::LibLinaear->train>>. i.e., C<Algorithm::LibLinear> is a factory class.

=head2 load(filename => $path)

Class method. Load a LIBLINEAR's model file and returns an instance of this class.

=head2 class_labels

Returns an ArrayRef of class labels, each of them could be returned by C<predict> and C<predict_values>.

=head2 is_probability_model

Returns true if the model is trained as a classifier based on logistic regression, else otherwise.

=head2 num_classes

The number of class labels.

=head2 num_features

The number of features contained in training set.

=head2 predict(feature => $hashref)

In case of classification, returns predicted class label.

In case of regression, returns value of estimated function given feature.

=head2 predict_probabilities(feature => $hashref)

Returns an ArrayRef of probabilities of the feature belonging to corresponding class.

This method raises an error if the model is not a classifier based on logistic regression (i.e., C<<not $classifier->is_probability_model>>.)

=head2 predict_values(feature => $hashref)

Returns an ArrayRef of decision values of each class (higher is better).

=head2 save(filename => $path)

Writes the model out as a LIBLINEAR model file.

=cut
