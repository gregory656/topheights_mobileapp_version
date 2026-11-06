import 'package:flutter/material.dart';
import '../../app/top_heights_theme.dart';
import '../../data/order_repository.dart';

String _money(int minor) =>
    'KES ${(minor ~/ 100)}.${(minor % 100).toString().padLeft(2, '0')}';

class RequestDesk extends StatefulWidget {
  const RequestDesk({super.key});
  @override
  State<RequestDesk> createState() => _RequestDeskState();
}

class _RequestDeskState extends State<RequestDesk>
    with SingleTickerProviderStateMixin {
  final _repo = OrderRepository();
  late final _tabs = TabController(length: 2, vsync: this);
  List<CartLine> _cart = [];
  List<LocalOrder> _orders = [];
  bool _busy = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final values = await Future.wait([_repo.cart(), _repo.orders()]);
    if (mounted) {
      setState(() {
        _cart = values[0] as List<CartLine>;
        _orders = values[1] as List<LocalOrder>;
        _busy = false;
      });
    }
  }

  int get _subtotal => _cart.fold(0, (s, l) => s + l.totalMinor);
  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _checkout() async {
    final form = GlobalKey<FormState>();
    final name = TextEditingController(),
        email = TextEditingController(),
        phone = TextEditingController(),
        address = TextEditingController();
    String preference = 'Delivery — details to confirm';
    final status = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Your request, your way'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'These details stay on this device. No payment is collected and no request is sent to Top Heights.',
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Name *'),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Add your name' : null,
                    ),
                    TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone *'),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Add a phone number' : null,
                    ),
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email (optional)',
                      ),
                    ),
                    TextFormField(
                      controller: address,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Delivery or site address *',
                      ),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Add an address' : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: preference,
                      decoration: const InputDecoration(
                        labelText: 'Preference',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Delivery — details to confirm',
                          child: Text('Delivery — details to confirm'),
                        ),
                        DropdownMenuItem(
                          value: 'Installation discussion requested',
                          child: Text('Discuss installation'),
                        ),
                        DropdownMenuItem(
                          value: 'Collection — details to confirm',
                          child: Text('Collection — details to confirm'),
                        ),
                      ],
                      onChanged: (v) => setDialog(() => preference = v!),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Delivery, installation and tax fees are not known yet. We do not estimate them here.',
                      style: TextStyle(color: BrandColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep browsing'),
            ),
            TextButton(
              onPressed: () {
                if (form.currentState!.validate()) {
                  Navigator.pop(ctx, 'Draft');
                }
              },
              child: const Text('Save draft'),
            ),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) {
                  Navigator.pop(ctx, 'Submitted locally');
                }
              },
              child: const Text('Save request locally'),
            ),
          ],
        ),
      ),
    );
    if (status == null) return;
    try {
      final order = await _repo.saveOrder(
        name: name.text,
        email: email.text,
        phone: phone.text,
        address: address.text,
        preference: preference,
        status: status,
      );
      await _load();
      if (mounted) {
        _tabs.animateTo(1);
        _openOrder(order);
      }
    } catch (e) {
      _toast(e.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _openOrder(LocalOrder order) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(order.reference),
        content: SizedBox(
          width: 430,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: BrandColors.paleGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.offline_pin_rounded,
                        color: BrandColors.forest,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${order.status}\nSaved on this device only',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                for (final line in order.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${line.quantity} × ${line.name}'),
                        ),
                        Text(_money(line.totalMinor)),
                      ],
                    ),
                  ),
                const Divider(),
                _row('Items subtotal', _money(order.subtotalMinor)),
                _row('Delivery / installation / tax', 'Not known'),
                const SizedBox(height: 12),
                Text('For ${order.customerName} · ${order.phone}'),
                Text(order.address),
                Text(order.preference),
                const SizedBox(height: 14),
                Text(
                  'Updated ${order.updatedAt.substring(0, 16).replaceFirst('T', ' ')} UTC',
                  style: const TextStyle(
                    fontSize: 11,
                    color: BrandColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (order.status != 'Cancelled')
            TextButton(
              onPressed: () async {
                await _repo.changeStatus(order.id, 'Cancelled');
                if (ctx.mounted) Navigator.pop(ctx);
                await _load();
              },
              child: const Text('Cancel locally'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _row(String a, String b) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(a)),
        Text(b, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F8F4),
    appBar: AppBar(
      title: const Text('Request desk'),
      bottom: TabBar(
        controller: _tabs,
        tabs: [
          Tab(text: 'Your basket (${_cart.length})'),
          Tab(text: 'Saved requests (${_orders.length})'),
        ],
      ),
    ),
    body: _busy
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(controller: _tabs, children: [_basket(), _history()]),
  );
  Widget _basket() => _cart.isEmpty
      ? _empty(
          Icons.shopping_basket_outlined,
          'A little room for good energy',
          'Add priced products from the catalogue to start a local request.',
        )
      : ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [BrandColors.forestDeep, BrandColors.forest],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE REQUEST DESK',
                    style: TextStyle(
                      color: Color(0xFFB8D69D),
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'A thoughtful shortlist.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Review quantities and save a request for later.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (final line in _cart)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: BrandColors.paleGreen,
                        child: Icon(
                          Icons.wb_sunny_outlined,
                          color: BrandColors.forest,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${_money(line.unitPriceMinor)} each',
                              style: const TextStyle(
                                color: BrandColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          if (line.quantity > 1) {
                            await _repo.setQuantity(
                              line.productId,
                              line.quantity - 1,
                            );
                          } else {
                            await _repo.remove(line.productId);
                          }
                          await _load();
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '${line.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        onPressed: () async {
                          if (line.quantity >= 999) {
                            _toast('Maximum quantity is 999.');
                            return;
                          }
                          await _repo.setQuantity(
                            line.productId,
                            line.quantity + 1,
                          );
                          await _load();
                        },
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        onPressed: () async {
                          await _repo.remove(line.productId);
                          await _load();
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _row('Items subtotal', _money(_subtotal)),
                    _row('Delivery and installation', 'Not known'),
                    _row('Tax', 'Not calculated'),
                    const Divider(),
                    _row('Total before unknown fees', _money(_subtotal)),
                    const SizedBox(height: 6),
                    const Text(
                      'Availability and delivery charges are confirmed later. This is not a payment or stock reservation.',
                      style: TextStyle(color: BrandColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _checkout,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Review & save request'),
            ),
          ],
        );
  Widget _history() => _orders.isEmpty
      ? _empty(
          Icons.auto_stories_outlined,
          'Your local story starts here',
          'Saved requests appear here with their original item and price snapshots.',
        )
      : ListView(
          padding: const EdgeInsets.all(18),
          children: [
            for (final order in _orders)
              Card(
                child: ListTile(
                  onTap: () => _openOrder(order),
                  leading: CircleAvatar(
                    backgroundColor: order.status == 'Cancelled'
                        ? const Color(0xFFF1E8E3)
                        : BrandColors.paleGreen,
                    child: Icon(
                      order.status == 'Cancelled'
                          ? Icons.block_rounded
                          : Icons.bolt_rounded,
                      color: BrandColors.forest,
                    ),
                  ),
                  title: Text(
                    order.reference,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${order.status} · ${order.items.length} lines · ${order.createdAt.substring(0, 10)}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _money(order.subtotalMinor),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 17),
                    ],
                  ),
                ),
              ),
          ],
        );
  Widget _empty(IconData icon, String title, String subtitle) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: BrandColors.paleGreen,
            child: Icon(icon, color: BrandColors.forest, size: 29),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: BrandColors.muted),
          ),
        ],
      ),
    ),
  );
}
