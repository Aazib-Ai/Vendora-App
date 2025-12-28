import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../errors/failures.dart';
import '../../../models/proposal.dart';

class ProposalRepository {
  final SupabaseConfig _supabaseConfig;

  ProposalRepository({SupabaseConfig? supabaseConfig}) 
      : _supabaseConfig = supabaseConfig ?? SupabaseConfig();

  // Get active proposals for display (Buyer side)
  Future<Either<Failure, List<Proposal>>> getActiveProposals() async {
    try {
      final response = await _supabaseConfig
          .from('proposals')
          .select()
          .eq('is_active', true)
          .order('priority', ascending: false)
          .order('created_at', ascending: false);

      final proposals = (response as List)
          .map((json) => Proposal.fromJson(json))
          .toList();
      
      return Right(proposals);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // Get all proposals (Admin side)
  Future<Either<Failure, List<Proposal>>> getAllProposals() async {
    try {
      final response = await _supabaseConfig
          .from('proposals')
          .select()
          .order('priority', ascending: false)
          .order('created_at', ascending: false);

      final proposals = (response as List)
          .map((json) => Proposal.fromJson(json))
          .toList();

      return Right(proposals);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // Create new proposal
  Future<Either<Failure, Proposal>> createProposal(Proposal proposal) async {
    try {
      final proposalData = proposal.toJson();
      // Remove ID to let DB generate it if it's new
      if (proposalData['id'] == '') {
        proposalData.remove('id');
      }
      
      final response = await _supabaseConfig
          .from('proposals')
          .insert(proposalData)
          .select()
          .single();

      return Right(Proposal.fromJson(response));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // Update proposal
  Future<Either<Failure, Proposal>> updateProposal(Proposal proposal) async {
    try {
      final response = await _supabaseConfig
          .from('proposals')
          .update(proposal.toJson())
          .eq('id', proposal.id)
          .select()
          .single();

      return Right(Proposal.fromJson(response));
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // Delete proposal
  Future<Either<Failure, void>> deleteProposal(String id) async {
    try {
      await _supabaseConfig
          .from('proposals')
          .delete()
          .eq('id', id);
      
      return const Right(null);
    } on PostgrestException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
