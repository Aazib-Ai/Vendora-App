import 'package:flutter/material.dart';
import '../../../../core/data/repositories/address_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../models/address.dart';

class AddressProvider extends ChangeNotifier {
  final IAddressRepository _addressRepository;

  List<Address> _addresses = [];
  bool _isLoading = false;
  String? _error;
  Address? _selectedAddress;

  AddressProvider({required IAddressRepository addressRepository})
      : _addressRepository = addressRepository;

  List<Address> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Address? get selectedAddress => _selectedAddress;

  void selectAddress(Address? address) {
    _selectedAddress = address;
    notifyListeners();
  }

  Future<void> loadAddresses(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _addressRepository.getUserAddresses(userId);

    result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (addresses) {
        _addresses = addresses;
        // Auto-select default address if none selected
        if (_selectedAddress == null && addresses.isNotEmpty) {
           final defaultAddress = addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => addresses.first,
          );
          _selectedAddress = defaultAddress;
        }
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> addAddress(Address address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _addressRepository.addAddress(address);

    result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (newAddress) {
        _isLoading = false;
        // Refresh list to handle default flag updates correctly
        loadAddresses(address.userId);
      },
    );
  }

  Future<void> updateAddress(Address address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _addressRepository.updateAddress(address);

    result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (updatedAddress) {
        _isLoading = false;
        loadAddresses(address.userId);
      },
    );
  }

  Future<void> deleteAddress(String addressId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _addressRepository.deleteAddress(addressId);

    result.fold(
      (failure) {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (_) {
        _isLoading = false;
        loadAddresses(userId);
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) return failure.message;
    return 'An unexpected error occurred';
  }
}
