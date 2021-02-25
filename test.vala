/* Compile: valac test.vala tflite.vapi -X -ltensorflowlite_c */

using TFLite;

void main()
{
    var model = Model.from_file("mnist.tflite");

    if (model == null)
    {
        warning("Error loading model");
        return;
    }

    var intrp = new Interpreter(model, null);
    intrp.allocate_tensors();

    assert(intrp.get_input_tensor(0).type == TFLite.TensorType.Float32);

    var input_data = new float[28 * 28];

    intrp.get_input_tensor(0).copy_from_buffer((uint8[]) input_data);
    intrp.invoke();

    var output_data = new float[10];
    // void *output_data_v = output_data;
    intrp.get_output_tensor(0).copy_to_buffer(output_data, sizeof(float) * 10);

    for (int i = 0; i < output_data.length; i++)
    {
        print(@"$i:\t$(((float*) intrp.get_output_tensor(0).get_data())[i])\n");
    }
}
