import 'package:app/helpers/image_crop.dart';
import 'package:app/models/face_model.dart';
import 'package:app/widget/round_input_hint_widget.dart';
import 'package:flutter/material.dart';
import 'package:app/helpers/toast.dart';

class PersonSelectWidget extends StatefulWidget {
  const PersonSelectWidget({Key? key, required this.people,required this.callback, required this.title, required this.hint, required this.okButtonText, required this.clearButtonText}) : super(key: key);
  final String title, hint, okButtonText, clearButtonText;
  final List<FaceModel> people;
  final Function(int, String) callback;

  static void show({required  List<FaceModel> people, required Function (int personId, String personName) callback,
    required BuildContext context, required String title, required String hint, required String okButtonText, required String clearButtonText}) {

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return PersonSelectWidget(people: people, callback:callback, title: title, hint: hint, okButtonText:okButtonText, clearButtonText: clearButtonText);
      },
    );
  }

  @override
  State<PersonSelectWidget> createState() => _PersonSelectWidgetState();
}

class _PersonSelectWidgetState extends State<PersonSelectWidget> {
  final TextEditingController personNameCtrl = TextEditingController();

  @override
  void dispose() {
    personNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RoundInputHint(ctrl: personNameCtrl, hintText: "New Name", onChanged: (_) => setState(() {})),
            const SizedBox(height: 10),
            if (widget.people.isNotEmpty)
              Text(widget.hint, style: const TextStyle(fontSize: 13, color: Colors.grey),),
            if (widget.people.isNotEmpty)
              const SizedBox(height: 10),
            if (widget.people.isNotEmpty)
              Scrollbar(
                child: SingleChildScrollView(
                  child: Theme(
                    data: ThemeData(canvasColor: Colors.black.withOpacity(0.5)),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10.0,
                      runSpacing: 6.0,
                      children: widget.people.
                      where((personFace) => personNameCtrl.text=="" || personFace.name.toLowerCase().contains(personNameCtrl.text.toLowerCase())).
                      map((personFace) => FilterChip(
                        backgroundColor: Colors.blue.withOpacity(0.5),
                        label: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 5, 10),
                          child: Text(personFace.name),
                        ),
                        showCheckmark: false,
                        avatar: FaceCropperWidget(faceRect: personFace.rect, asset: personFace.asset, width: 500, height: 500, shape: BoxShape.circle),
                        selected: false,
                        labelStyle: const TextStyle(color: Colors.white),
                        onSelected: (_) => widget.callback(personFace.personId, personFace.name),
                      )
                      ).toList(),
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(widget.clearButtonText, style: const TextStyle(color: Colors.red)),
          onPressed: () {
            Navigator.of(context).pop();
            widget.callback(0, "");
          },
        ),
        TextButton(
          child: Text(widget.okButtonText),
          onPressed: () {
            final personName = personNameCtrl.text;
            if (personName.isEmpty) {
              Toast.show(msg: "Please enter a name", gravity: Toast.ToastGravityCenter);
              return;
            }
            Navigator.of(context).pop();
            widget.callback(-1, personNameCtrl.text);
          },
        ),
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
