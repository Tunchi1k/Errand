import 'package:flutter/material.dart';

class PostTaskPage extends StatefulWidget {
  const PostTaskPage({super.key});

  @override
  _PostTaskPageState createState() => _PostTaskPageState();
}

class _PostTaskPageState extends State<PostTaskPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  double _urgency = 5;

  void _searchForRunner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchingForRunnerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Post Task",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 50),
              _buildTextField(
                _descriptionController,
                "Task Description",
                Icons.assignment,
                maxLines: 1,
              ),
              SizedBox(height: 20),
              _buildTextField(_fromController, "From", Icons.location_pin),
              SizedBox(height: 20),
              _buildTextField(_toController, "To", Icons.location_on),
              SizedBox(height: 20),
              _buildTextField(
                _priceController,
                "Price (ZMW)",
                Icons.money_sharp,
                isNumber: true,
              ),
              SizedBox(height: 20),
              Text(
                "Urgency",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Slider(
                value: _urgency,
                min: 1,
                max: 10,
                divisions: 9,
                label: _urgency.round().toString(),
                activeColor: const Color.fromARGB(
                  255,
                  0,
                  63,
                  97,
                ), // Change this to your desired color
                inactiveColor: Colors.grey, // Change this to your desired color
                onChanged: (value) {
                  setState(() {
                    _urgency = value;
                  });
                },
              ),
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _searchForRunner,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 63, 97),
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(60),
                    ),
                  ),
                  child: Text(
                    "Find Runner",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w500),
        ),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: label,
            suffixIcon: Icon(icon, color: Colors.black),
          ),
        ),
      ],
    );
  }
}

class SearchingForRunnerPage extends StatefulWidget {
  const SearchingForRunnerPage({super.key});

  @override
  _SearchingForRunnerPageState createState() => _SearchingForRunnerPageState();
}

class _SearchingForRunnerPageState extends State<SearchingForRunnerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat(reverse: false);

    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Search",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Stack(
          alignment: Alignment(0, -0.3),
          children: [
            Align(
              alignment: Alignment.center,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Container(
                    width: 380 * _animation.value,
                    height: 750 * _animation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(
                        0.3 * (1 - _animation.value),
                      ),
                    ),
                  );
                },
              ),
            ),

            Align(
              alignment: Alignment.center,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color.fromARGB(255, 0, 63, 97),
                ),
                child: Center(
                  child: Icon(
                    Icons.directions_run,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            // Keep the text inside the center but outside the animated circle
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 90),
                child: Text(
                  "Searching for a runner...",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
