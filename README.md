![](screenshot.png)

This small app aims to demonstrate how machine learning can be integrated into desktop Linux applications.

### Using a neural network in your app

Neural networks are numerical models which take an array of numbers as an input, and produce an array of numbers as an output.
In machine learning, the technical term for such an array is a 'tensor'. Tensors usually have more than 1 dimensions.
To use a neural network, you first need to copy data into its input tensor. When invoked, the network will be run on the input data and the output will be stored in the output tensor.

A tensor is a technical term for a multi-dimentional array.
Any network you find will have one or more input tensors and one or more output tensors.
Before .., the input tensor of a network needs to be filled with data. When invoked, the data is processed by the neural network and the output tensor is filled with the result. This can then be copied out and used.

### Using pre-trained models
Models for doing common tasks already exist online and you can download and use them directly in your program. In cases where models work on something else than numerical data, you may have to do some preprocessing yourself.

### Converting h5 files for use with TFLite

Many pre-trained models are available on sites like [ModelZoo](http://www.modelzoo.co/) or the [TensorFlow Hub](https://tfhub.dev/).

To convert a model saved as a .h5 file to TFLite's format, enter the following commands into Python:

	import tensorflow as tf
	m = tf.keras.models.load_model('mnist.h5')
	converter = tf.lite.TFLiteConverter.from_keras_model(m)
	tflite_model = converter.convert()
	open("mnist.tflite", "wb").write(tflite_model)


Weights for the demo come from here: https://www.kaggle.com/josephassaker/cnn-mnist-digit-classification/output?select=best_model.hdf5
