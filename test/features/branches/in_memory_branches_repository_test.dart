import 'package:flutter_test/flutter_test.dart';
import 'package:purificadora/features/branches/data/repositories/in_memory_branches_repository.dart';
import 'package:purificadora/features/branches/domain/entities/branch.dart';
import 'package:purificadora/features/branches/domain/entities/product.dart';
import 'package:purificadora/features/branches/domain/errors/branches_exception.dart';

void main() {
  late InMemoryBranchesRepository repository;

  setUp(() {
    repository = InMemoryBranchesRepository(
      initialBranches: const [
        Branch(
          id: 'b1',
          name: 'Centro',
          businessName: 'Negocio Demo',
          address: 'Calle Centro 100',
          latitude: 29.07,
          longitude: -110.95,
        ),
        Branch(
          id: 'b2',
          name: 'Norte',
          businessName: 'Negocio Demo',
          address: 'Calle Norte 200',
          latitude: 29.17,
          longitude: -110.96,
        ),
      ],
      initialProducts: const [
        Product(id: 'p1', name: 'Agua 20 L', sku: 'AGUA-20L', basePrice: 45),
        Product(id: 'p2', name: 'Hielo 5 kg', sku: 'HIELO-5KG', basePrice: 38),
      ],
      initialAssignments: const {
        'b1': {'p1'},
        'b2': {'p2'},
      },
    );
  });

  test('configura productos distintos por sucursal', () async {
    await repository.configureBranchProducts('b1', {'p2'});

    expect(await repository.getBranchProductIds('b1'), {'p2'});
    expect(await repository.getBranchProductIds('b2'), {'p2'});
  });

  test('completa el CRUD de sucursales', () async {
    final created = await repository.createBranch(
      const Branch(
        name: 'Sur',
        businessName: 'Negocio Demo',
        address: 'Calle Sur 300',
        latitude: 28.95,
        longitude: -110.94,
      ),
    );
    final updated = await repository.updateBranch(
      Branch(
        id: created.id,
        name: 'Sur Actualizada',
        businessName: created.businessName,
        address: created.address,
        latitude: created.latitude,
        longitude: created.longitude,
      ),
    );
    expect(updated.name, 'Sur Actualizada');

    await repository.deleteBranch(created.id);
    expect(
      (await repository.getBranches()).any((item) => item.id == created.id),
      isFalse,
    );
  });

  test('completa el CRUD de productos', () async {
    final created = await repository.createProduct(
      const Product(name: 'Botella 1 L', sku: 'AGUA-1L', basePrice: 18),
    );
    final updated = await repository.updateProduct(
      Product(
        id: created.id,
        name: 'Botella 1 litro',
        sku: created.sku,
        basePrice: 20,
      ),
    );
    expect(updated.basePrice, 20);

    await repository.deleteProduct(created.id);
    expect(
      (await repository.getProducts()).any((item) => item.id == created.id),
      isFalse,
    );
  });

  test('el borrado lógico de producto desactiva sus asignaciones', () async {
    await repository.deleteProduct('p2');

    expect(await repository.getBranchProductIds('b2'), isEmpty);
    expect((await repository.getProducts()).map((item) => item.id), ['p1']);

    final recreated = await repository.createProduct(
      const Product(name: 'Hielo nuevo', sku: 'HIELO-5KG', basePrice: 40),
    );
    expect(recreated.sku, 'HIELO-5KG');
  });

  test('el borrado lógico de sucursal la oculta con sus relaciones', () async {
    await repository.deleteBranch('b1');

    expect((await repository.getBranches()).map((item) => item.id), ['b2']);
    expect(
      () => repository.getBranchProductIds('b1'),
      throwsA(isA<BranchesException>()),
    );
  });

  test('rechaza asignar un producto eliminado', () async {
    await repository.deleteProduct('p1');

    expect(
      () => repository.configureBranchProducts('b1', {'p1'}),
      throwsA(isA<BranchesException>()),
    );
  });
}
