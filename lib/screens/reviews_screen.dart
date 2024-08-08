import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ReviewsScreen extends StatefulWidget {
  final SupabaseClient supabase;
  final PageController pageController;

  const ReviewsScreen({super.key, required this.supabase, required this.pageController});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final commentController = TextEditingController();
  bool loading = true;
  bool working = false;
  late List opinion;
  late int rating;

  @override
  void initState() {
    fetchOpinion();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (loading == true) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      return Scaffold(
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Rating $rating'),
                RatingBar(
                  initialRating: rating.toDouble(),
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  ratingWidget: RatingWidget(
                    full: const Icon(Icons.star_rate, color: Colors.redAccent,),
                    half: const Icon(Icons.star_half_outlined, color: Colors.redAccent,),
                    empty: const Icon(Icons.star_outline_outlined, color: Colors.redAccent,),
                  ),
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  onRatingUpdate: (ratingValue) {
                    setState(() {
                      rating = ratingValue.toInt();
                    });
                  },
                ),
                myCustomButton(loading: working, label: 'save rating', icon: Icons.save_as_outlined, onTap: saveRating),
                const SizedBox(height: 50),
                const Text('Comment'),
                const SizedBox(height: 20),
                TextFormField(
                  maxLines: 8,
                  controller: commentController,
                  decoration: const InputDecoration(
                    //hintText: 'The email address?',
                    labelText: 'comment',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0)),
                    ),
                  ),
                ),
                myCustomButton(
                    loading: working, label: 'save comment', icon: Icons.save_as_outlined, onTap: saveComment),
              ],
            )),
      );
    }
  }

  Widget myCustomButton({required bool loading, required label, required IconData icon, required onTap}) {
    final Color btn_default = (loading == true) ? Color.fromARGB(255, 166, 185, 176) : Color.fromARGB(255, 3, 99, 32);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 25,
                padding: const EdgeInsets.fromLTRB(20, 0, 35, 0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: btn_default,
                    width: 2,
                  ),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
                ),
                child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: btn_default)),
              ),
              Positioned(
                right: -5,
                top: -6,
                child: CircleAvatar(
                  maxRadius: 18,
                  backgroundColor: btn_default,
                  child: Icon(
                    icon,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  void fetchOpinion() async {
    final userId = widget.supabase.auth.currentUser!.id;
    try {
      final data =
          await widget.supabase.schema('eaquasaver').from('opinion').select('comment, rating').eq('submitter', userId);
      if (data.isNotEmpty) {
        debugPrint("{$data[0]}");
        setState(() {
          //opinion;
          commentController.text = data[0]['comment'];
          rating = data[0]['rating'];
        });
      } else {
        setState(() {
          opinion = [];
        });
      }
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void saveComment() async {
    FocusScope.of(context).unfocus();
    debugPrint('saveComment called !!!!!!!!!!!');
    setState(() {
      working = true;
    });
    try {
      final userId = widget.supabase.auth.currentUser!.id;
      final data = await widget.supabase
          .schema('eaquasaver')
          .from('opinion')
          .upsert({'submitter': userId, 'comment': commentController.text}, onConflict: 'submitter').select();

      if (data.isNotEmpty) {
        //OK
      }
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException: $e');
    } finally {
      setState(() {
        working = false;
      });
    }
  }

  void saveRating() async {
    setState(() {
      working = true;
    });
    try {
      final userId = widget.supabase.auth.currentUser!.id;
      final data = await widget.supabase
          .schema('eaquasaver')
          .from('opinion')
          .upsert({'submitter': userId, 'rating': rating}, onConflict: 'submitter').select();

      if (data.isNotEmpty) {
        //OK
      }
    } on PostgrestException catch (e) {
      debugPrint('PostgrestException: $e');
    } finally {
      setState(() {
        working = false;
      });
    }
  }
}