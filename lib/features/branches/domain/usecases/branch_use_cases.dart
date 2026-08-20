import '../entities/branch.dart';
import '../repositories/branches_repository.dart';

class GetBranches {
  const GetBranches(this._repository);
  final BranchesRepository _repository;
  Future<List<Branch>> call() => _repository.getBranches();
}

class CreateBranch {
  const CreateBranch(this._repository);
  final BranchesRepository _repository;
  Future<Branch> call(Branch branch) => _repository.createBranch(branch);
}

class UpdateBranch {
  const UpdateBranch(this._repository);
  final BranchesRepository _repository;
  Future<Branch> call(Branch branch) => _repository.updateBranch(branch);
}

class DeleteBranch {
  const DeleteBranch(this._repository);
  final BranchesRepository _repository;
  Future<void> call(String id) => _repository.deleteBranch(id);
}
