import 'package:flutter/material.dart';
import '../../../../models/proposal.dart';
import '../../../../core/data/repositories/proposal_repository.dart';

class ProposalProvider extends ChangeNotifier {
  final ProposalRepository _proposalRepository;

  List<Proposal> _proposals = [];
  bool _isLoading = false;
  String? _error;

  List<Proposal> get proposals => _proposals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // For Admin/Seller: all proposals
  List<Proposal> _allProposals = [];
  List<Proposal> get allProposals => _allProposals;

  ProposalProvider({
    required ProposalRepository proposalRepository,
  }) : _proposalRepository = proposalRepository;

  // Load active proposals for Buyer
  Future<void> loadActiveProposals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _proposalRepository.getActiveProposals();

    result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (proposals) {
        _proposals = proposals;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Load all proposals for Admin
  Future<void> loadAllProposals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _proposalRepository.getAllProposals();

    result.fold(
      (failure) {
        _error = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (proposals) {
        _allProposals = proposals;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> createProposal(Proposal proposal) async {
    _isLoading = true;
    notifyListeners();

    final result = await _proposalRepository.createProposal(proposal);

    result.fold(
      (failure) {
        _error = failure.message;
      },
      (newProposal) {
        // Optimistic update or refetch
        _allProposals.insert(0, newProposal);
        if (newProposal.isActive) {
          _proposals.insert(0, newProposal);
          _sortProposals();
        }
      },
    );
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProposal(Proposal proposal) async {
    _isLoading = true;
    notifyListeners();

    final result = await _proposalRepository.updateProposal(proposal);

    result.fold(
      (failure) {
        _error = failure.message;
      },
      (updatedProposal) {
        // Update local lists
        final index = _allProposals.indexWhere((p) => p.id == updatedProposal.id);
        if (index != -1) {
          _allProposals[index] = updatedProposal;
        }

        // Handle active list logic
        final activeIndex = _proposals.indexWhere((p) => p.id == updatedProposal.id);
        if (updatedProposal.isActive) {
          if (activeIndex != -1) {
            _proposals[activeIndex] = updatedProposal;
          } else {
            _proposals.add(updatedProposal);
          }
           _sortProposals();
        } else {
          if (activeIndex != -1) {
            _proposals.removeAt(activeIndex);
          }
        }
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteProposal(String id) async {
    _isLoading = true;
    notifyListeners();

    final result = await _proposalRepository.deleteProposal(id);

    result.fold(
      (failure) {
        _error = failure.message;
      },
      (_) {
        _allProposals.removeWhere((p) => p.id == id);
        _proposals.removeWhere((p) => p.id == id);
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  void _sortProposals() {
    _proposals.sort((a, b) {
      if (b.priority != a.priority) return b.priority.compareTo(a.priority);
      return b.createdAt.compareTo(a.createdAt);
    });
  }
}
