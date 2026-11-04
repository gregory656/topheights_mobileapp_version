import 'package:flutter/material.dart';
import '../../app/top_heights_theme.dart';
import '../../data/catalogue_repository.dart';
import '../shell/brand_mark.dart';

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});
  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  final _repo = CatalogueRepository();
  final _search = TextEditingController();
  List<CatalogueCategory> _categories = [];
  List<CatalogueProduct> _products = [];
  List<CatalogueProduct> _recent = [];
  String _category = '', _sort = 'name', _availability = '';
  bool _favourites = false, _loading = true;
  final Set<String> _compare = {};
  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }
  Future<void> _load() async {
    try {
      final result = await Future.wait([_repo.categories(), _repo.products(query: _search.text, categoryId: _category, favouritesOnly: _favourites, availability: _availability, sort: _sort), _repo.recentlyViewed()]);
      if (!mounted) return;
      setState(() { _categories = result[0] as List<CatalogueCategory>; _products = result[1] as List<CatalogueProduct>; _recent = result[2] as List<CatalogueProduct>; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }
  String _id() => DateTime.now().microsecondsSinceEpoch.toString();
  Future<void> _edit([CatalogueProduct? product]) async {
    final saved = await showDialog<bool>(context: context, builder: (_) => _ProductEditor(product: product, categories: _categories, id: _id));
    if (saved == true) _load();
  }
  Future<void> _categoryEditor() async {
    final name = TextEditingController(); final description = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Add a category'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'Category name')), TextField(controller: description, decoration: const InputDecoration(labelText: 'Description (optional)'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () { if (name.text.trim().isEmpty) return; Navigator.pop(context, true); }, child: const Text('Save'))]));
    if (ok == true) { try { await _repo.saveCategory(CatalogueCategory('cat_${_id()}', name.text, description.text)); } catch (_) { if (mounted) _message('A category with that name may already exist.'); } await _load(); }
  }
  Future<void> _editCategory(CatalogueCategory category) async {
    final name = TextEditingController(text: category.name); final description = TextEditingController(text: category.description);
    final action = await showDialog<String>(context: context, builder: (context) => AlertDialog(title: const Text('Edit category'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Category name')), TextField(controller: description, decoration: const InputDecoration(labelText: 'Description'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(context, 'delete'), child: const Text('Remove')), FilledButton(onPressed: () { if (name.text.trim().isNotEmpty) Navigator.pop(context, 'save'); }, child: const Text('Save'))]));
    if (action == 'save') { try { await _repo.saveCategory(CatalogueCategory(category.id, name.text, description.text)); } catch (_) { if (mounted) _message('A category with that name already exists.'); } await _load(); }
    if (action == 'delete' && mounted) { final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Remove this category?'), content: const Text('Products in this category will be kept and become uncategorised.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove'))])); if (confirm == true) { await _repo.deleteCategory(category.id); if (_category == category.id) _category = ''; await _load(); } }
  }
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _detail(CatalogueProduct p) async { await _repo.markViewed(p.id); if (!mounted) return; await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (context) => _ProductDetail(product: p, onFavourite: () async { await _repo.toggleFavourite(p); if (context.mounted) Navigator.pop(context); _load(); }, onEdit: () { Navigator.pop(context); _edit(p); })); await _load(); }
  Future<void> _compareSelected() async {
    final items = _products.where((p) => _compare.contains(p.id)).toList();
    if (items.length < 2) {
      _message('Select at least two products to compare.');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Side-by-side comparison'),
        content: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((product) {
              return SizedBox(
                width: 210,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _compareLine('SKU', product.sku),
                        _compareLine('Model', product.model),
                        _compareLine('Price', _price(product.priceMinor)),
                        _compareLine('Stock', _stock(product)),
                        _compareLine('Warranty', product.warranty),
                        for (final entry in product.specifications.entries)
                          _compareLine(entry.key, entry.value),
                        if (product.specifications.isEmpty)
                          const Text('No specifications recorded', style: TextStyle(color: BrandColors.muted)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ],
      ),
    );
  }
  Widget _compareLine(String label, String value) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('$label\n${value.isEmpty ? 'Not recorded' : value}', style: const TextStyle(fontSize: 12, height: 1.4)));
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final pad = constraints.maxWidth > 800 ? 34.0 : 18.0;
    return SingleChildScrollView(padding: EdgeInsets.fromLTRB(pad, 12, pad, 36), child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _ShopHero(onAdd: () => _edit(), onManage: _categoryEditor),
      const SizedBox(height: 22),
      TextField(controller: _search, onChanged: (_) => _load(), decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: 'Search products, SKUs, models or specifications', suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); _load(); }, icon: const Icon(Icons.close_rounded)))),
      const SizedBox(height: 15),
      SizedBox(height: 43, child: ListView(scrollDirection: Axis.horizontal, children: [ChoiceChip(label: const Text('Everything'), selected: _category.isEmpty, onSelected: (_) => setState(() { _category = ''; _load(); })), const SizedBox(width: 8), ..._categories.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(onLongPress: () => _editCategory(c), child: Tooltip(message: 'Long press to edit or remove', child: ChoiceChip(label: Text(c.name), selected: _category == c.id, onSelected: (_) => setState(() { _category = c.id; _load(); })))))) ])),
      const SizedBox(height: 14),
      Wrap(spacing: 9, runSpacing: 9, crossAxisAlignment: WrapCrossAlignment.center, children: [FilterChip(label: const Text('Favourites'), avatar: const Icon(Icons.favorite_border, size: 16), selected: _favourites, onSelected: (v) { setState(() => _favourites = v); _load(); }), DropdownButton<String>(value: _availability, underline: const SizedBox(), items: const [DropdownMenuItem(value: '', child: Text('Any availability')), DropdownMenuItem(value: 'available', child: Text('Recorded available')), DropdownMenuItem(value: 'unavailable', child: Text('Recorded unavailable'))], onChanged: (v) { setState(() => _availability = v ?? ''); _load(); }), DropdownButton<String>(value: _sort, underline: const SizedBox(), items: const [DropdownMenuItem(value: 'name', child: Text('Name A–Z')), DropdownMenuItem(value: 'price', child: Text('Price: low to high')), DropdownMenuItem(value: 'newest', child: Text('Recently added'))], onChanged: (v) { setState(() => _sort = v ?? 'name'); _load(); }), OutlinedButton.icon(onPressed: _compareSelected, icon: const Icon(Icons.compare_arrows_rounded), label: Text('Compare${_compare.isEmpty ? '' : ' (${_compare.length})'}')), TextButton.icon(onPressed: _categoryEditor, icon: const Icon(Icons.create_new_folder_outlined), label: const Text('Add category'))]),
      const SizedBox(height: 14),
      if (_loading) const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator())) else if (_products.isEmpty) _EmptyCatalogue(searching: _search.text.isNotEmpty, onAdd: () => _edit(), onClear: () { _search.clear(); setState(() { _category = ''; _favourites = false; }); _load(); }) else LayoutBuilder(builder: (context, c) { final columns = c.maxWidth >= 960 ? 3 : c.maxWidth >= 620 ? 2 : 1; return GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _products.length, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 13, crossAxisSpacing: 13, mainAxisExtent: 230), itemBuilder: (context, i) => _ProductCard(product: _products[i], selected: _compare.contains(_products[i].id), onTap: () => _detail(_products[i]), onEdit: () => _edit(_products[i]), onSelect: (v) => setState(() { v ? _compare.add(_products[i].id) : _compare.remove(_products[i].id); }), onFavourite: () async { await _repo.toggleFavourite(_products[i]); _load(); }, onDelete: () async { final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Remove this product?'), content: const Text('This permanently removes the local product record.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove'))])); if (ok == true) { await _repo.deleteProduct(_products[i].id); _load(); } })); }),
      if (_recent.isNotEmpty && _search.text.isEmpty && _category.isEmpty && !_favourites) ...[const SizedBox(height: 32), Text('Recently viewed', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: _recent.map((p) => ActionChip(avatar: const Icon(Icons.history_rounded, size: 16), label: Text(p.name), onPressed: () => _detail(p))).toList())]
    ]))));
  });
}

String _price(int? minor) => minor == null ? 'Price not recorded' : 'KES ${(minor / 100).toStringAsFixed(2)}';
String _stock(CatalogueProduct p) => p.stock == null && p.availability == 'unknown' ? 'Stock not recorded' : '${p.stock == null ? '' : '${p.stock} recorded'}${p.stock != null && p.availability != 'unknown' ? ' · ' : ''}${p.availability == 'unknown' ? '' : p.availability}';

class _ShopHero extends StatelessWidget {
  const _ShopHero({required this.onAdd, required this.onManage}); final VoidCallback onAdd, onManage;
  @override Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(23), decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), gradient: const LinearGradient(colors: [BrandColors.forestDeep, BrandColors.forest, Color(0xFF27664A)])), child: Stack(children: [Positioned(right: -8, top: -13, child: Opacity(opacity: .88, child: Image.asset('assets/TopHeightsTransparent.png', width: 135, height: 145, fit: BoxFit.contain))), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('THE LIVING CATALOGUE', style: TextStyle(color: BrandColors.leaf, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w800)), const SizedBox(height: 8), Text('Good energy,\nwell chosen.', style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white, fontSize: 31)), const SizedBox(height: 8), const Text('Your locally managed solar & electrical catalogue.', style: TextStyle(color: Color(0xFFD3E1D6))), const SizedBox(height: 17), Wrap(spacing: 9, children: [FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: const Text('Add a product')), TextButton.icon(onPressed: onManage, icon: const Icon(Icons.tune_rounded), label: const Text('Categories', style: TextStyle(color: Colors.white)))])]) ]));
}

class _EmptyCatalogue extends StatelessWidget { const _EmptyCatalogue({required this.searching, required this.onAdd, required this.onClear}); final bool searching; final VoidCallback onAdd, onClear; @override Widget build(BuildContext context) => Container(width: double.infinity, margin: const EdgeInsets.only(top: 6), padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23), border: Border.all(color: BrandColors.line)), child: Column(children: [const BrandMark(size: 48), const SizedBox(height: 13), Text(searching ? 'No matches yet' : 'Your catalogue starts here', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 6), Text(searching ? 'Try a different name, SKU or specification, or clear filters.' : 'Add real product and category records. Empty categories stay empty until you enter inventory.', textAlign: TextAlign.center), const SizedBox(height: 14), Wrap(spacing: 8, children: [FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add product')), if (searching) TextButton(onPressed: onClear, child: const Text('Clear search & filters'))]) ])); }

class _ProductCard extends StatelessWidget { const _ProductCard({required this.product, required this.selected, required this.onTap, required this.onEdit, required this.onSelect, required this.onFavourite, required this.onDelete}); final CatalogueProduct product; final bool selected; final VoidCallback onTap, onEdit, onFavourite, onDelete; final ValueChanged<bool> onSelect; @override Widget build(BuildContext context) => Card(child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(22), child: Padding(padding: const EdgeInsets.all(17), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium)), IconButton(visualDensity: VisualDensity.compact, tooltip: product.favourite ? 'Remove favourite' : 'Add favourite', onPressed: onFavourite, icon: Icon(product.favourite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: product.favourite ? Colors.redAccent : BrandColors.muted)), PopupMenuButton<String>(onSelected: (v) => v == 'edit' ? onEdit() : onDelete(), itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Remove'))])]), Text([if (product.sku.isNotEmpty) 'SKU ${product.sku}', if (product.model.isNotEmpty) product.model].join(' · ').isEmpty ? 'No SKU or model recorded' : [if (product.sku.isNotEmpty) 'SKU ${product.sku}', if (product.model.isNotEmpty) product.model].join(' · '), style: const TextStyle(color: BrandColors.muted, fontSize: 11)), const Spacer(), Text(_price(product.priceMinor), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: BrandColors.forest)), const SizedBox(height: 3), Text(_stock(product), style: const TextStyle(fontSize: 11, color: BrandColors.muted)), const Divider(height: 19), Row(children: [Expanded(child: Text(product.specifications.isEmpty ? 'Specifications not recorded' : product.specifications.entries.take(2).map((e) => '${e.key}: ${e.value}').join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: BrandColors.muted))), Checkbox(value: selected, onChanged: (v) => onSelect(v == true), visualDensity: VisualDensity.compact), const Text('Compare', style: TextStyle(fontSize: 10))])])))); }

class _ProductDetail extends StatelessWidget {
  const _ProductDetail({required this.product, required this.onFavourite, required this.onEdit});
  final CatalogueProduct product;
  final VoidCallback onFavourite, onEdit;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(23, 24, 23, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              const BrandMark(size: 38),
              const SizedBox(width: 11),
              Expanded(child: Text(product.name, style: Theme.of(context).textTheme.headlineMedium)),
              IconButton(onPressed: onFavourite, icon: Icon(product.favourite ? Icons.favorite : Icons.favorite_border)),
            ]),
            const SizedBox(height: 8),
            Text(product.description.isEmpty ? 'No description recorded.' : product.description),
            const SizedBox(height: 15),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _fact('SKU', product.sku),
              _fact('Model', product.model),
              _fact('Price', _price(product.priceMinor)),
              _fact('Stock · locally recorded', _stock(product)),
              _fact('Warranty', product.warranty),
              _fact('Installation', product.installation ? 'Professional installation required' : 'Not specified'),
            ]),
            const SizedBox(height: 17),
            Text('Technical specifications', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 7),
            if (product.specifications.isEmpty)
              const Text('No technical specifications recorded yet. Compatibility cannot be determined from the available information.')
            else
              ...product.specifications.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Expanded(child: Text(entry.key)),
                  Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
              )),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined), label: const Text('Edit product')),
          ],
        ),
      ),
    ),
  );

  Widget _fact(String label, String value) => Container(
    width: 155,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(color: BrandColors.paper, borderRadius: BorderRadius.circular(13)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: BrandColors.muted)),
        const SizedBox(height: 3),
        Text(value.isEmpty ? 'Not recorded' : value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _ProductEditor extends StatefulWidget { const _ProductEditor({this.product, required this.categories, required this.id}); final CatalogueProduct? product; final List<CatalogueCategory> categories; final String Function() id; @override State<_ProductEditor> createState() => _ProductEditorState(); }
class _ProductEditorState extends State<_ProductEditor> {
  final _form = GlobalKey<FormState>(); late final _name = TextEditingController(text: widget.product?.name); late final _sku = TextEditingController(text: widget.product?.sku); late final _model = TextEditingController(text: widget.product?.model); late final _description = TextEditingController(text: widget.product?.description); late final _price = TextEditingController(text: widget.product?.priceMinor == null ? '' : (widget.product!.priceMinor! / 100).toStringAsFixed(2)); late final _stock = TextEditingController(text: widget.product?.stock?.toString() ?? ''); late final _warranty = TextEditingController(text: widget.product?.warranty); late final _specs = TextEditingController(text: widget.product?.specifications.entries.map((e) => '${e.key}: ${e.value}').join('\n') ?? ''); late String _category = widget.product?.categoryId ?? ''; late String _availability = widget.product?.availability ?? 'unknown'; late bool _install = widget.product?.installation ?? false;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.product == null ? 'Add a product' : 'Edit product'),
    content: SizedBox(
      width: 500,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(_name, 'Product name', required: true),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Uncategorised')),
                  ...widget.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => _category = v ?? '',
              ),
              _field(_sku, 'SKU'),
              _field(_model, 'Model'),
              _field(_description, 'Description', lines: 3),
              Row(children: [
                Expanded(child: _field(_price, 'Price (KES)', keyboard: const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 10),
                Expanded(child: _field(_stock, 'Stock quantity', keyboard: TextInputType.number)),
              ]),
              DropdownButtonFormField<String>(
                initialValue: _availability,
                decoration: const InputDecoration(labelText: 'Availability'),
                items: const [
                  DropdownMenuItem(value: 'unknown', child: Text('Not recorded')),
                  DropdownMenuItem(value: 'available', child: Text('Available (locally recorded)')),
                  DropdownMenuItem(value: 'unavailable', child: Text('Unavailable (locally recorded)')),
                ],
                onChanged: (v) => _availability = v ?? 'unknown',
              ),
              _field(_warranty, 'Warranty text'),
              _field(_specs, 'Technical specifications · one “field: value” per line', lines: 4),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _install,
                onChanged: (v) => setState(() => _install = v ?? false),
                title: const Text('Professional installation required'),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: _save, child: const Text('Save product')),
    ],
  );
  Widget _field(TextEditingController c, String label, {bool required = false, int lines = 1, TextInputType? keyboard}) => Padding(padding: const EdgeInsets.only(bottom: 8), child: TextFormField(controller: c, maxLines: lines, keyboardType: keyboard, decoration: InputDecoration(labelText: label), validator: required ? (v) => v == null || v.trim().isEmpty ? 'Required' : null : null));
  Future<void> _save() async { if (!_form.currentState!.validate()) return; int? minor; if (_price.text.trim().isNotEmpty) { final amount = double.tryParse(_price.text.trim()); if (amount == null || amount < 0) { _showError('Enter a valid non-negative KES price.'); return; } minor = (amount * 100).round(); } int? stock; if (_stock.text.trim().isNotEmpty) { stock = int.tryParse(_stock.text.trim()); if (stock == null || stock < 0) { _showError('Enter a whole, non-negative stock quantity.'); return; } } final specs = <String, String>{}; for (final line in _specs.text.split('\n')) { final i = line.indexOf(':'); if (i > 0 && line.substring(i + 1).trim().isNotEmpty) specs[line.substring(0, i).trim()] = line.substring(i + 1).trim(); } final p = CatalogueProduct(id: widget.product?.id ?? widget.id(), name: _name.text, categoryId: _category, sku: _sku.text, model: _model.text, description: _description.text, priceMinor: minor, stock: stock, availability: _availability, installation: _install, warranty: _warranty.text, imageRef: '', specifications: specs, favourite: widget.product?.favourite ?? false); try { await CatalogueRepository().saveProduct(p); if (mounted) Navigator.pop(context, true); } catch (e) { _showError(e.toString()); } }
  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
