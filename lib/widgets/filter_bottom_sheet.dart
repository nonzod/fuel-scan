import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fuel_scan/providers/fuel_stations_provider.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FuelStationsProvider _provider;
  late FuelType _selectedFuelType;
  late SortOption _sortOption;
  late double _maxDistance;
  late bool _onlySelfService;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<FuelStationsProvider>(context, listen: false);
    _selectedFuelType = _provider.selectedFuelType;
    _sortOption = _provider.sortOption;
    _maxDistance = _provider.maxDistance;
    _onlySelfService = _provider.onlySelfService;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtri',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Tipo di carburante',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildFuelTypeSelector(),
          const SizedBox(height: 16),
          const Text(
            'Ordina per',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildSortOptionSelector(),
          const SizedBox(height: 16),
          const Text(
            'Distanza massima',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildDistanceSlider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _onlySelfService,
                onChanged: (value) {
                  setState(() {
                    _onlySelfService = value ?? false;
                  });
                },
              ),
              const Text('Solo self service'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () {
                  _applyFilters();
                  Navigator.of(context).pop();
                },
                child: const Text('Applica'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFuelTypeSelector() {
    return Wrap(
      spacing: 8.0,
      children: FuelType.values.map((type) {
        return ChoiceChip(
          label: Text(_getFuelTypeName(type)),
          selected: _selectedFuelType == type,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedFuelType = type;
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildSortOptionSelector() {
    return Wrap(
      spacing: 8.0,
      children: SortOption.values.map((option) {
        return ChoiceChip(
          label: Text(_getSortOptionName(option)),
          selected: _sortOption == option,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _sortOption = option;
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildDistanceSlider() {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: _maxDistance,
            min: 1.0,
            max: 50.0,
            divisions: 49,
            label: '${_maxDistance.round()} km',
            onChanged: (value) {
              setState(() {
                _maxDistance = value;
              });
            },
          ),
        ),
        Text('${_maxDistance.round()} km'),
      ],
    );
  }

  void _applyFilters() {
    _provider.setSelectedFuelType(_selectedFuelType);
    _provider.setSortOption(_sortOption);
    _provider.setMaxDistance(_maxDistance);
    _provider.setOnlySelfService(_onlySelfService);
  }

  String _getFuelTypeName(FuelType type) {
    switch (type) {
      case FuelType.benzina:
        return 'Benzina';
      case FuelType.gasolio:
        return 'Gasolio';
      case FuelType.gpl:
        return 'GPL';
      case FuelType.metano:
        return 'Metano';
      default:
        return '';
    }
  }

  String _getSortOptionName(SortOption option) {
    switch (option) {
      case SortOption.distance:
        return 'Distanza';
      case SortOption.price:
        return 'Prezzo';
      case SortOption.name:
        return 'Nome';
      default:
        return '';
    }
  }
}