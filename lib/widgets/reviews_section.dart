import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/patient_api.dart';
import '../auth/auth_controller.dart';
import '../auth/patient_guard.dart';
import '../theme.dart';
import 'form_fields.dart';
import 'stars.dart';

const _months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];

/// Avis des patients et « J'aime » d'un hôpital ou d'un infirmier (comme sur le site web).
class ReviewsSection extends StatefulWidget {
  const ReviewsSection({super.key, required this.target, required this.id, required this.name});

  final ReviewTarget target;
  final int id;

  /// Nom affiché dans « Votre avis sur … ».
  final String name;

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  late final PatientApi _api = PatientApiScope.of(context);
  ReviewsPage? _page;
  Object? _error;
  bool _liking = false;
  int? _loadedForUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recharge après une connexion ou une déconnexion : « mon avis » et « j'aime » dépendent de la personne.
    final userId = AuthScope.of(context).user?.id;
    if (_page == null || userId != _loadedForUser) {
      _loadedForUser = userId;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final page = await _api.reviews(widget.target, widget.id);
      if (mounted) {
        setState(() {
          _page = page;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _showError(Object error) {
    final message = error is ApiException ? error.userMessage : 'Une erreur est survenue.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleLike() async {
    final page = _page;
    if (page == null) return;
    setState(() => _liking = true);
    try {
      final updated = await _api.setLiked(widget.target, widget.id, liked: !page.likedByMe);
      if (mounted) setState(() => _page = updated);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  Future<void> _openForm() async {
    final page = _page;
    if (page == null) return;
    final updated = await showModalBottomSheet<ReviewsPage>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ReviewForm(
        api: _api,
        target: widget.target,
        id: widget.id,
        name: widget.name,
        initialRating: page.myRating,
        initialComment: page.myComment,
      ),
    );
    if (updated != null && mounted) setState(() => _page = updated);
  }

  /// Avis et « J'aime » demandent un compte patient (pas un compte infirmier).
  void _asPatient(VoidCallback action) => runAsPatient(context, action, allowNurse: false);

  @override
  Widget build(BuildContext context) {
    final page = _page;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Avis des patients', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (page == null)
            _error != null
                ? Row(
                    children: [
                      const Expanded(child: Text('Impossible de charger les avis.')),
                      TextButton(onPressed: _load, child: const Text('Réessayer')),
                    ],
                  )
                : const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
          else ...[
            _Summary(page: page),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _asPatient(_openForm),
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  label: Text(page.myRating == null ? 'Donner mon avis' : 'Modifier mon avis'),
                ),
                OutlinedButton.icon(
                  onPressed: _liking ? null : () => _asPatient(_toggleLike),
                  icon: Icon(
                    page.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 18,
                    color: const Color(0xFFE11D48),
                  ),
                  label: Text(page.likedByMe ? 'J\'aime (${page.summary.likesCount})' : 'J\'aime'),
                ),
              ],
            ),
            if (page.reviews.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final review in page.reviews) _ReviewTile(review: review),
            ],
          ],
        ],
      ),
    );
  }
}

/// Note moyenne en grand, puis la répartition des notes de 5 à 1 étoiles.
class _Summary extends StatelessWidget {
  const _Summary({required this.page});

  final ReviewsPage page;

  @override
  Widget build(BuildContext context) {
    final summary = page.summary;
    final average = summary.average;
    if (average == null || summary.reviewsCount == 0) {
      return const Text('Pas encore d\'avis. Soyez le premier à partager votre expérience.');
    }

    final total = summary.reviewsCount;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Text(
              average.toStringAsFixed(1).replaceAll('.', ','),
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: LafiaColors.ink),
            ),
            Stars(rating: average),
            const SizedBox(height: 4),
            Text('$total avis', style: const TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            children: [
              for (var rating = 5; rating >= 1; rating--)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(width: 14, child: Text('$rating', style: const TextStyle(fontSize: 12))),
                      const Icon(Icons.star_rounded, size: 12, color: starColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (page.distribution[rating] ?? 0) / total,
                            minHeight: 6,
                            backgroundColor: LafiaColors.greyTint,
                            color: starColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final date = review.updatedAt;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: LafiaColors.greyTint))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(review.author, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
              const SizedBox(width: 8),
              Stars(rating: review.rating.toDouble(), size: 14),
              const Spacer(),
              Text('${date.day} ${_months[date.month - 1]} ${date.year}', style: const TextStyle(fontSize: 11)),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(review.comment!, style: const TextStyle(fontSize: 14, color: LafiaColors.body)),
          ],
        ],
      ),
    );
  }
}

/// Feuille « Votre avis » : note obligatoire, commentaire facultatif ; un seul avis, modifiable.
class _ReviewForm extends StatefulWidget {
  const _ReviewForm({
    required this.api,
    required this.target,
    required this.id,
    required this.name,
    required this.initialRating,
    required this.initialComment,
  });

  final PatientApi api;
  final ReviewTarget target;
  final int id;
  final String name;
  final int? initialRating;
  final String? initialComment;

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  late int _rating = widget.initialRating ?? 0;
  late final _comment = TextEditingController(text: widget.initialComment);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _run(Future<ReviewsPage> Function() call) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final page = await call();
      if (mounted) Navigator.of(context).pop(page);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.userMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _save() {
    if (_rating == 0) {
      setState(() => _error = 'Choisissez une note de 1 à 5 étoiles.');
      return;
    }
    final comment = _comment.text.trim();
    _run(() => widget.api.saveReview(
          widget.target,
          widget.id,
          rating: _rating,
          comment: comment.isEmpty ? null : comment,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Votre avis sur ${widget.name}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text('Votre prénom et l\'initiale de votre nom s\'affichent avec l\'avis.'),
              const SizedBox(height: 12),
              StarInput(value: _rating, onChanged: (value) => setState(() => _rating = value)),
              const SizedBox(height: 12),
              LabeledField(
                label: 'Commentaire (facultatif)',
                controller: _comment,
                icon: Icons.notes_rounded,
                hint: 'Accueil, attente, explications…',
                maxLength: 500,
                textInputAction: TextInputAction.done,
              ),
              if (_error != null) FormErrorBanner(message: _error!),
              SubmitButton(label: 'Publier mon avis', busy: _busy, onPressed: _save),
              if (widget.initialRating != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : () => _run(() => widget.api.deleteReview(widget.target, widget.id)),
                  child: const Text('Supprimer mon avis'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
