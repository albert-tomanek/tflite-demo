// A thin wrapper around the TensorFlow Lite C API. Should be pretty version agnostic as this API aims for ABI stability.
// Documentation is in header file. https://github.com/tensorflow/tensorflow/blob/master/tensorflow/lite/c/c_api.h
// This vapi is hand-crafted.

[CCode(cheader_filename = "tensorflow/lite/c/c_api.h", cprefix = "TfLite")]		// Only applies to types by the looks of it
namespace TFLite
{
	[CCode(cname = "TfLiteStatus", cprefix = "kTfLite", has_type_id = false)]
	enum Status
	{
		Ok,
		Error,				// Error in interpreter
		DelegateError,		// Error within TfLiteDelegate
		ApplicationError,	// Incompatibility between runtime and delegate (see .h)
	}

	[CCode(cname = "TfLiteType", cprefix = "kTfLite", has_type_id = false)]
	enum TensorType
	{
		NoType,
		Float32,
		Int32,
		UInt8,
		Int64,
		String,
		Bool,
		Int16,
		Complex64,
		Int8,
		Float16,
		Float64,
		Complex128,
		UInt64,
		Resource,
		Variant,
	}

	[CCode(cname = "TfLiteVersion")]
	unowned string version();

	[CCode(free_function = "TfLiteModelDelete")]
	[Compact]
	class Model
	{
		[CCode(cname = "TfLiteModelCreate")]
		public static Model? @new(void *model_data, size_t size);

		[CCode(cname = "TfLiteModelCreateFromFile")]
		public static Model? from_file(string path);
	}

	[CCode(free_function = "TfLiteInterpreterOptionsDelete")]
	[Compact]
	class InterpreterOptions
	{
		[CCode(cname = "TfLiteInterpreterOptionsCreate")]
		public InterpreterOptions();

		[CCode(cname = "TfLiteInterpreterOptionsSetNumThreads")]
		public void set_num_threads(int32 num_threads);

		// public void add_delegate ?

		// [CCode(delegate_target = true, delegate_target_pos = 0)]
		// [CCode(cname = "void (*)(void *, const char *, va_list)")]
		public delegate void ErrorReporter(string format, va_list args);	// Warning: You can't create one of these as a variable, as it doesn't translate to C correctly. You just have to pass a function name directly.
		[CCode(cname = "TfLiteInterpreterOptionsSetErrorReporter")]
		public void set_error_reporter([CCode(type = "void (*)(void *, const char *, va_list)")] ErrorReporter reporter);
	}

	[CCode(free_function = "TfLiteInterpreterDelete")]
	[Compact]
	class Interpreter
	{
		[CCode(cname = "TfLiteInterpreterCreate")]
		public Interpreter(Model model, InterpreterOptions? options = null);

		[CCode(cname = "TfLiteInterpreterAllocateTensors")]
		public Status allocate_tensors();

		[CCode(cname = "TfLiteInterpreterInvoke")]
		public Status invoke();

		[CCode(cname = "TfLiteInterpreterGetInputTensorCount")]
		public int32 get_input_tensor_count();

		[CCode(cname = "TfLiteInterpreterGetInputTensor")]
		public unowned Tensor? get_input_tensor(int32 index);

		[CCode(cname = "TfLiteInterpreterResizeInputTensor")]
		public Status resize_input_tensor(int32 index, int[] dims);

		[CCode(cname = "TfLiteInterpreterGetOutputTensorCount")]
		public int32 get_output_tensor_count();

		[CCode(cname = "TfLiteInterpreterGetOutputTensor")]
		public unowned Tensor? get_output_tensor(int32 index);
	}

	// [CCode(free_function = "TfLiteTensorDelete")]	// Apparently we only get weak references to these. Probably freed when the Interpreter is freed.
	[Compact]
	class Tensor
	{
		public TensorType type {
			[CCode(cname = "TfLiteTensorType")]
			get;
		}

		public int32 num_dims {
			[CCode(cname = "TfLiteTensorNumDims")]
			get;
		}

		[CCode(cname = "TfLiteTensorDim")]
		public int32 get_dim(int32 index);

		[CCode(cname = "TfLiteTensorByteSize")]
		public size_t size_bytes();

		[CCode(cname = "TfLiteTensorData")]
		public void *get_data();

		public string name {
			[CCode(cname = "TfLiteTensorName")]
			get;
		}

		[CCode(cname = "TfLiteTensorCopyFromBuffer")]
		public Status copy_from_buffer(uint8[] input_data);

		[CCode(cname = "TfLiteTensorCopyToBuffer")]
		public Status copy_to_buffer(void *dest, size_t bytes);
		// public Status copy_to_buffer([CCode(array_length = false)] out uint8[] dest, size_t bytes);
	}
}
