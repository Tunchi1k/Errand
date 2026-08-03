import 'package:cloud_firestore/cloud_firestore.dart';

class Errand {
  const Errand({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.pickupLocation,
    required this.deliveryLocation,
    required this.reward,
    required this.distance,
    required this.postedAgo,
    required this.senderRating,
    required this.estimatedTime,
    required this.senderName,
    required this.price,
  });

  final String id;
  final String category;
  final String title;
  final String description;
  final String pickupLocation;
  final String deliveryLocation;
  final String reward;
  final String distance;
  final String postedAgo;
  final double senderRating;
  final String estimatedTime;
  final String senderName;
  final double price;

  factory Errand.fromFirestore(String id, Map<String, dynamic> data) {
    final price = data['price'];
    final createdAt = data['createdAt'];
    final urgency = data['urgency'];

    return Errand(
      id: id,
      category: data['category']?.toString() ?? 'Other',
      title: data['title']?.toString() ?? 'Untitled Errand',
      description: data['description']?.toString() ?? '',
      pickupLocation: data['pickupLocation']?.toString() ?? '',
      deliveryLocation:
          data['dropoffLocation']?.toString() ??
          data['deliveryLocation']?.toString() ??
          '',
      reward: _formatReward(price),
      distance: data['distance']?.toString() ?? 'Nearby',
      postedAgo: _formatPostedAgo(createdAt),
      senderRating: (data['senderRating'] as num?)?.toDouble() ?? 0,
      estimatedTime:
          data['estimatedTime']?.toString() ??
          _estimateTimeFromUrgency(urgency),
      senderName: data['senderName']?.toString() ?? 'Sender',
      price: price is num ? price.toDouble() : 0,
    );
  }

  static String _formatReward(dynamic price) {
    if (price is! num) return 'K0';

    final hasDecimals = price % 1 != 0;
    return 'K${price.toStringAsFixed(hasDecimals ? 2 : 0)}';
  }

  static String _formatPostedAgo(dynamic createdAt) {
    if (createdAt is! Timestamp) return 'Just now';

    final difference = DateTime.now().difference(createdAt.toDate());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    }
    if (difference.inHours < 24) return '${difference.inHours} hours ago';

    return '${difference.inDays} days ago';
  }

  static String _estimateTimeFromUrgency(dynamic urgency) {
    final level = urgency is num ? urgency.round() : 3;
    if (level >= 5) return '15 min';
    if (level >= 4) return '25 min';
    if (level >= 2) return '35 min';
    return '45 min';
  }
}

abstract class ErrandRepository {
  Stream<List<Errand>> watchAvailableErrands();
  Future<AcceptErrandResult> acceptErrand({
    required String errandId,
    required String runnerId,
  });
}

class FirestoreErrandRepository implements ErrandRepository {
  const FirestoreErrandRepository();

  @override
  Stream<List<Errand>> watchAvailableErrands() {
    return FirebaseFirestore.instance
        .collection('errands')
        .where('status', isEqualTo: 'Active')
        .snapshots()
        .map((snapshot) {
          final docs = [...snapshot.docs];
          docs.sort((a, b) {
            final aCreatedAt = a.data()['createdAt'];
            final bCreatedAt = b.data()['createdAt'];

            if (aCreatedAt is Timestamp && bCreatedAt is Timestamp) {
              return bCreatedAt.compareTo(aCreatedAt);
            }

            return 0;
          });

          return docs
              .map((doc) => Errand.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  @override
  Future<AcceptErrandResult> acceptErrand({
    required String errandId,
    required String runnerId,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(runnerId);
    final errandRef = firestore.collection('errands').doc(errandId);
    final activeRunnerErrands =
        await firestore
            .collection('errands')
            .where('runnerId', isEqualTo: runnerId)
            .where('status', whereIn: ['Accepted', 'In Progress'])
            .limit(1)
            .get();

    if (activeRunnerErrands.docs.isNotEmpty) {
      return AcceptErrandResult.activeErrandExists;
    }

    return firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final errandSnapshot = await transaction.get(errandRef);

      if (!userSnapshot.exists) {
        return AcceptErrandResult.userNotFound;
      }

      final floats = userSnapshot.data()?['floats'];
      if (floats is! num || floats <= 0) {
        return AcceptErrandResult.noFloats;
      }

      if (!errandSnapshot.exists) {
        return AcceptErrandResult.errandUnavailable;
      }

      final errandData = errandSnapshot.data() ?? {};
      final status = errandData['status']?.toString();
      final assignedRunner = errandData['runnerId'];

      if (status != 'Active' || assignedRunner != null) {
        return AcceptErrandResult.errandUnavailable;
      }

      transaction.update(errandRef, {
        'runnerId': runnerId,
        'status': 'Accepted',
        'deliveryStatus': 'headingToPickup',
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return AcceptErrandResult.accepted;
    });
  }
}

enum AcceptErrandResult {
  accepted,
  noFloats,
  activeErrandExists,
  errandUnavailable,
  userNotFound,
}
