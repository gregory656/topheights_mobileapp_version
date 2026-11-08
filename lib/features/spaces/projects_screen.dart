import 'package:flutter/material.dart';

import '../../app/top_heights_theme.dart';
import '../../data/project_repository.dart';

String _moneyLabel(Object? value, String currency) {
  if (value == null) return 'Price not entered';
  final minor = value as int;
  return '$currency ${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}';
}

int? _parseKesMinor(String value) {
  final parts = value.trim().replaceAll(',', '').split('.');
  if (parts.isEmpty || parts.length > 2) return null;
  final whole = int.tryParse(parts.first);
  if (whole == null || whole < 0) return null;
  final centsText = parts.length == 1 ? '' : parts[1];
  if (centsText.length > 2 ||
      (centsText.isNotEmpty && int.tryParse(centsText) == null)) {
    return null;
  }
  final cents = centsText.isEmpty ? 0 : int.parse(centsText.padRight(2, '0'));
  return whole * 100 + cents;
}

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});
  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen>
    with SingleTickerProviderStateMixin {
  final _repo = ProjectRepository();
  late final _tabs = TabController(length: 3, vsync: this);
  List<Map<String, Object?>> _projects = [],
      _quotes = [],
      _visits = [],
      _assessments = [],
      _products = [];
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
    try {
      final result = await Future.wait([
        _repo.projects(),
        _repo.quotes(),
        _repo.visitRequests(),
        _repo.assessments(),
        _repo.products(),
      ]);
      if (mounted) {
        setState(() {
          _projects = result[0];
          _quotes = result[1];
          _visits = result[2];
          _assessments = result[3];
          _products = result[4];
          _busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _toast('Could not open local project records: $e');
      }
    }
  }

  void _toast(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));
  String _date(Object? value) => value == null
      ? ''
      : value.toString().replaceFirst('T', ' ').substring(0, 16);
  String _money(Object? value, String currency) => _moneyLabel(value, currency);

  Future<void> _newQuote({Map<String, Object?>? quote}) async {
    final title = TextEditingController(
      text: quote?['title'] as String? ?? 'Energy project quote',
    );
    final validity = TextEditingController(),
        assumptions = TextEditingController(),
        notes = TextEditingController();
    final current =
        (quote?['versions'] as List?)?.cast<Map<String, Object?>>() ?? [];
    final oldSnapshot = current.isEmpty
        ? <String, Object?>{}
        : Map<String, Object?>.from(current.first['snapshot'] as Map);
    validity.text = oldSnapshot['validUntil'] as String? ?? '';
    assumptions.text =
        oldSnapshot['assumptions'] as String? ??
        'Preliminary scope; subject to site assessment and business review.';
    notes.text = oldSnapshot['notes'] as String? ?? '';
    String? assessmentId = quote?['assessment_id'] as String?;
    final selected = <String, Map<String, Object?>>{};
    for (final item in (oldSnapshot['items'] as List? ?? [])) {
      final row = Map<String, Object?>.from(item as Map);
      selected[row['productId'] as String? ?? 'custom_${row['name']}'] = row;
    }
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          title: Text(
            quote == null ? 'Build a quote draft' : 'Create quote revision',
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Saved on this device only. Prices are user-entered and unverified unless copied from the local catalogue.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Quote name'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: assessmentId,
                    decoration: const InputDecoration(
                      labelText: 'Linked assessment (optional)',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No assessment selected'),
                      ),
                      ..._assessments.map(
                        (a) => DropdownMenuItem<String?>(
                          value: a['id'] as String,
                          child: Text(a['name'] as String),
                        ),
                      ),
                    ],
                    onChanged: (v) => refresh(() => assessmentId = v),
                  ),
                  const SizedBox(height: 13),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Catalogue items',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (_products.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'No local catalogue items yet. You can still save assumptions and notes.',
                      ),
                    ),
                  ..._products.map((p) {
                    final id = p['id'] as String;
                    final existing = selected[id];
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: existing != null,
                      title: Text(p['name'] as String),
                      subtitle: Text(
                        existing == null
                            ? 'Catalogue price: ${_money(p['price_minor'], 'KES')}'
                            : '${existing['quantity']} × ${_money(existing['unitPriceMinor'], 'KES')} · ${existing['priceSource']}',
                      ),
                      onChanged: (v) => refresh(() {
                        if (v == true) {
                          selected[id] = {
                            'productId': id,
                            'name': p['name'],
                            'quantity': 1,
                            'unitPriceMinor': p['price_minor'],
                            'currency': 'KES',
                            'priceSource': p['price_minor'] == null
                                ? 'User-entered · unverified'
                                : 'Local catalogue · unverified',
                          };
                        } else {
                          selected.remove(id);
                        }
                      }),
                    );
                  }),
                  for (final entry in selected.entries)
                    if (!entry.key.startsWith('custom_'))
                      _quoteLineEditor(entry.value, () => refresh(() {})),
                  const SizedBox(height: 8),
                  TextField(
                    controller: validity,
                    decoration: const InputDecoration(
                      labelText: 'Valid until (optional)',
                      hintText: 'YYYY-MM-DD',
                    ),
                  ),
                  TextField(
                    controller: assumptions,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Assumptions'),
                  ),
                  TextField(
                    controller: notes,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save version'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final snapshot = <String, Object?>{
      'schemaVersion': 1,
      'items': selected.values.toList(),
      'assumptions': assumptions.text.trim(),
      'validUntil': validity.text.trim(),
      'notes': notes.text.trim(),
      'currency': 'KES',
    };
    try {
      await _repo.saveQuote(
        id: quote?['id'] as String?,
        title: title.text,
        assessmentId: assessmentId,
        snapshot: snapshot,
      );
      await _load();
      _toast('Quote version saved locally.');
    } catch (e) {
      _toast(e.toString());
    }
  }

  Widget _quoteLineEditor(
    Map<String, Object?> item,
    VoidCallback changed,
  ) => Padding(
    padding: const EdgeInsets.only(left: 12, bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            '${item['name']} · ${item['priceSource']}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        SizedBox(
          width: 65,
          child: TextFormField(
            initialValue: '${item['quantity']}',
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Qty'),
            onChanged: (v) {
              item['quantity'] = int.tryParse(v) ?? 1;
              changed();
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 130,
          child: TextFormField(
            initialValue: item['unitPriceMinor'] == null
                ? ''
                : ((item['unitPriceMinor'] as int) / 100).toStringAsFixed(2),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Unit price (KES)'),
            onChanged: (v) {
              item['unitPriceMinor'] = _parseKesMinor(v);
              item['priceSource'] = 'User-entered · unverified';
              changed();
            },
          ),
        ),
      ],
    ),
  );

  Future<void> _newVisit() async {
    final name = TextEditingController(),
        phone = TextEditingController(),
        email = TextEditingController(),
        address = TextEditingController(),
        notes = TextEditingController(),
        access = TextEditingController(),
        preferredWindow = TextEditingController();
    String? assessmentId;
    final windows = <String>{};
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          title: const Text('Request a site assessment'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This request stays on this device. No staff member is assigned and no appointment is confirmed.',
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Contact name *',
                    ),
                  ),
                  TextField(
                    controller: phone,
                    decoration: const InputDecoration(labelText: 'Phone *'),
                    keyboardType: TextInputType.phone,
                  ),
                  TextField(
                    controller: email,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: address,
                    decoration: const InputDecoration(
                      labelText: 'Site address *',
                    ),
                  ),
                  TextField(
                    controller: notes,
                    decoration: const InputDecoration(labelText: 'Site notes'),
                    minLines: 2,
                    maxLines: 3,
                  ),
                  TextField(
                    controller: access,
                    decoration: const InputDecoration(
                      labelText: 'Access constraints',
                    ),
                    minLines: 2,
                    maxLines: 3,
                  ),
                  DropdownButtonFormField<String?>(
                    initialValue: assessmentId,
                    decoration: const InputDecoration(
                      labelText: 'Linked assessment',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No assessment selected'),
                      ),
                      ..._assessments.map(
                        (a) => DropdownMenuItem<String?>(
                          value: a['id'] as String,
                          child: Text(a['name'] as String),
                        ),
                      ),
                    ],
                    onChanged: (v) => refresh(() => assessmentId = v),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: preferredWindow,
                          decoration: const InputDecoration(
                            labelText: 'Preferred date and time window',
                            hintText: 'e.g. 2026-12-04, 09:00–12:00',
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Add preferred window',
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          final value = preferredWindow.text.trim();
                          if (value.isNotEmpty) {
                            refresh(() {
                              windows.add(value);
                              preferredWindow.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  for (final window in windows)
                    Chip(
                      label: Text(window),
                      onDeleted: () => refresh(() => windows.remove(window)),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save request'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final id = await _repo.saveVisit(
        assessmentId: assessmentId,
        contact: name.text,
        phone: phone.text,
        email: email.text,
        address: address.text,
        notes: notes.text,
        access: access.text,
        windows: windows.toList(),
      );
      await _repo.createProject(
        title: 'Site assessment · ${address.text.trim()}',
        requestId: id,
        assessmentId: assessmentId,
      );
      await _load();
      _toast('Request and local project timeline saved. Nothing was sent.');
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _createProject({Map<String, Object?>? quote}) async {
    final controller = TextEditingController(
      text: quote?['title'] as String? ?? 'My energy project',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create project timeline'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Project name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create locally'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _repo.createProject(
          title: controller.text,
          quoteId: quote?['id'] as String?,
          assessmentId: quote?['assessment_id'] as String?,
        );
        await _load();
        _toast('Project planned locally.');
      } catch (e) {
        _toast(e.toString());
      }
    }
  }

  Future<void> _projectDetail(Map<String, Object?> project) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: SizedBox(
          width: 720,
          height: MediaQuery.sizeOf(ctx).height * .88,
          child: ProjectDetail(
            repository: _repo,
            project: project,
            onChanged: _load,
            onShare: (text) => showDialog<void>(
              context: ctx,
              builder: (c) => AlertDialog(
                title: const Text('Shareable local summary'),
                content: SelectableText(text),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await _load();
  }

  Future<void> _quoteDetail(Map<String, Object?> quote) async {
    final versions = (quote['versions'] as List).cast<Map<String, Object?>>();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(quote['title'] as String),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _status(quote['status'] as String),
                const SizedBox(height: 10),
                const Text(
                  'Saved locally · pending business review. A local acceptance is not binding approval.',
                ),
                const SizedBox(height: 10),
                for (final version in versions) ...[
                  const Divider(),
                  Text(
                    'Version ${version['version']} · ${_date(version['created_at'])}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if ((version['snapshot'] as Map)['recordedStatus'] != null)
                    Text(
                      'Recorded at this version: ${(version['snapshot'] as Map)['recordedStatus']} · ${_date((version['snapshot'] as Map)['statusRecordedAt'])}',
                    ),
                  _snapshot(version['snapshot'] as Map),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _newQuote(quote: quote);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Create revision'),
          ),
          TextButton(
            onPressed: () async {
              await _repo.recordQuoteAction(
                quote['id'] as String,
                'Accepted locally — pending business review',
              );
              if (ctx.mounted) Navigator.pop(ctx);
              await _load();
            },
            child: const Text('Record local acceptance'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _createProject(quote: quote);
            },
            child: const Text('Create project'),
          ),
        ],
      ),
    );
    await _load();
  }

  Widget _snapshot(Map snapshot) {
    final items = (snapshot['items'] as List? ?? []).cast<Map>();
    final sum = items.fold<int>(
      0,
      (s, i) =>
          s +
          (((i['unitPriceMinor'] as int? ?? 0) * (i['quantity'] as int? ?? 1))),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final i in items)
          Text(
            '${i['quantity']} × ${i['name']} · ${_money(i['unitPriceMinor'], 'KES')} each · ${i['priceSource']}',
          ),
        Text('Items subtotal: ${_money(sum, 'KES')}'),
        if ((snapshot['validUntil'] as String? ?? '').isNotEmpty)
          Text('Valid until: ${snapshot['validUntil']}'),
        if ((snapshot['assumptions'] as String? ?? '').isNotEmpty)
          Text('Assumptions: ${snapshot['assumptions']}'),
        if ((snapshot['notes'] as String? ?? '').isNotEmpty)
          Text('Notes: ${snapshot['notes']}'),
      ],
    );
  }

  Widget _status(String text) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: BrandColors.paleGreen,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: BrandColors.forest,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F8F4),
    appBar: AppBar(
      title: const Text('Projects & quotes'),
      bottom: TabBar(
        controller: _tabs,
        tabs: [
          Tab(text: 'Projects (${_projects.length})'),
          Tab(text: 'Quotes (${_quotes.length})'),
          Tab(text: 'Site visits (${_visits.length})'),
        ],
      ),
    ),
    body: _busy
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabs,
            children: [_projectList(), _quoteList(), _visitList()],
          ),
    floatingActionButton: PopupMenuButton<String>(
      tooltip: 'Create project record',
      icon: const Icon(Icons.add),
      onSelected: (v) {
        if (v == 'quote') {
          _newQuote();
        } else {
          _newVisit();
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'quote', child: Text('New quote draft')),
        PopupMenuItem(value: 'visit', child: Text('Request site assessment')),
      ],
    ),
  );
  Widget _projectList() => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      _banner(
        'YOUR PROJECT JOURNEY',
        'Requested, planned locally and confirmed by business are shown as separate states.',
      ),
      if (_projects.isEmpty)
        _empty(
          'No project timelines yet',
          'Create a quote or request a site assessment to begin.',
        ),
      for (final p in _projects)
        Card(
          child: ListTile(
            onTap: () => _projectDetail(p),
            leading: const CircleAvatar(
              backgroundColor: BrandColors.paleGreen,
              child: Icon(Icons.timeline_rounded, color: BrandColors.forest),
            ),
            title: Text(
              p['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${p['status']} · ${(p['milestones'] as List).length} milestones · updated ${_date(p['updated_at'])}',
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
    ],
  );
  Widget _quoteList() => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      _banner(
        'QUOTE DRAFTS',
        'Each revision preserves the full earlier snapshot. Catalogue prices are still unverified.',
      ),
      if (_quotes.isEmpty)
        _empty(
          'No quote drafts saved',
          'Build a draft from your assessment and selected local catalogue items.',
        ),
      for (final q in _quotes) _quoteCard(q),
    ],
  );
  Widget _quoteCard(Map<String, Object?> q) {
    final versions = (q['versions'] as List).cast<Map<String, Object?>>();
    final snap = versions.isEmpty
        ? <String, Object?>{}
        : Map<String, Object?>.from(versions.first['snapshot'] as Map);
    return Card(
      child: ListTile(
        onTap: () => _quoteDetail(q),
        leading: const CircleAvatar(
          backgroundColor: BrandColors.paleGreen,
          child: Icon(Icons.request_quote_outlined, color: BrandColors.forest),
        ),
        title: Text(
          q['title'] as String,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${q['status']} · v${q['current_version']} · ${((snap['items'] as List?) ?? []).length} lines',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _visitList() => ListView(
    padding: const EdgeInsets.all(18),
    children: [
      _banner(
        'SITE VISIT REQUESTS',
        'Preferred windows are requests only. No appointment is confirmed and no staff member is assigned.',
      ),
      if (_visits.isEmpty)
        _empty(
          'No site requests saved',
          'Add a preferred window, contact details and site access notes.',
        ),
      for (final v in _visits)
        Card(
          child: ExpansionTile(
            title: Text(
              v['address'] as String,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(v['status'] as String),
            childrenPadding: const EdgeInsets.fromLTRB(17, 0, 17, 18),
            children: [
              Text('${v['contact_name']} · ${v['contact_phone']}'),
              Text('Preferred: ${(v['preferred_windows'] as List).join(', ')}'),
              if ((v['site_notes'] as String).isNotEmpty)
                Text('Site notes: ${v['site_notes']}'),
              if ((v['access_constraints'] as String).isNotEmpty)
                Text('Access: ${v['access_constraints']}'),
              Text('Saved ${_date(v['created_at'])}'),
            ],
          ),
        ),
    ],
  );
  Widget _banner(String title, String body) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: BrandColors.forestDeep,
      borderRadius: BorderRadius.circular(19),
    ),
    child: Text(
      '$title\n$body',
      style: const TextStyle(
        color: Colors.white,
        height: 1.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
  Widget _empty(String title, String body) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 25),
    child: Column(
      children: [
        const Icon(
          Icons.folder_open_outlined,
          size: 38,
          color: BrandColors.forest,
        ),
        const SizedBox(height: 10),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: BrandColors.muted),
        ),
      ],
    ),
  );
}

class ProjectDetail extends StatefulWidget {
  const ProjectDetail({
    super.key,
    required this.repository,
    required this.project,
    required this.onChanged,
    required this.onShare,
  });
  final ProjectRepository repository;
  final Map<String, Object?> project;
  final Future<void> Function() onChanged;
  final ValueChanged<String> onShare;
  @override
  State<ProjectDetail> createState() => _ProjectDetailState();
}

class _ProjectDetailState extends State<ProjectDetail> {
  late Map<String, Object?> _p = widget.project;
  Future<void> _refresh() async {
    final all = await widget.repository.projects();
    if (mounted) {
      final found = all.where((p) => p['id'] == _p['id']);
      if (found.isNotEmpty) setState(() => _p = found.first);
      await widget.onChanged();
    }
  }

  Future<void> _edit(Map<String, Object?> m) async {
    final title = TextEditingController(text: m['title'] as String),
        details = TextEditingController(text: (m['details'] as String?) ?? ''),
        date = TextEditingController(text: (m['target_date'] as String?) ?? '');
    var state = m['state'] as String;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          title: const Text('Edit milestone'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Milestone'),
                ),
                TextField(
                  controller: details,
                  decoration: const InputDecoration(labelText: 'Details'),
                  minLines: 2,
                  maxLines: 4,
                ),
                TextField(
                  controller: date,
                  decoration: const InputDecoration(
                    labelText: 'Target date (optional)',
                    hintText: 'YYYY-MM-DD',
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: state,
                  decoration: const InputDecoration(labelText: 'State'),
                  items:
                      const [
                            'Requested',
                            'Planned locally',
                            'Confirmed by business',
                            'Complete',
                          ]
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (v) => refresh(() => state = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await widget.repository.updateMilestone(
        _p['id'] as String,
        m['id'] as String,
        title.text,
        details.text,
        state,
        date.text,
      );
      await _refresh();
    }
  }

  Future<void> _document() async {
    final name = TextEditingController(), ref = TextEditingController();
    String kind = 'Note';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          title: const Text('Add document record'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Metadata and a reference are saved locally. Files are not uploaded.',
              ),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Document name'),
              ),
              DropdownButtonFormField<String>(
                initialValue: kind,
                items:
                    const [
                          'Note',
                          'Quote summary',
                          'External file reference',
                          'Other',
                        ]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: (v) => refresh(() => kind = v!),
              ),
              TextField(
                controller: ref,
                decoration: const InputDecoration(
                  labelText: 'Local or external reference (optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save record'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await widget.repository.addDocument(
        _p['id'] as String,
        name.text,
        kind,
        ref.text,
      );
      await _refresh();
    }
  }

  String _summary() {
    final milestones = (_p['milestones'] as List).cast<Map<String, Object?>>();
    final events = (_p['events'] as List).cast<Map<String, Object?>>();
    final quote = (_p['quote'] as Map?)?.cast<String, Object?>() ?? {};
    final assessment =
        (_p['assessment'] as Map?)?.cast<String, Object?>() ?? {};
    final assessmentPayload =
        (assessment['payload'] as Map?)?.cast<String, Object?>() ?? {};
    final quoteSnapshot =
        (quote['snapshot'] as Map?)?.cast<String, Object?>() ?? {};
    final quoteItems = (quoteSnapshot['items'] as List? ?? []).cast<Map>();
    final lines = quoteItems
        .map(
          (i) =>
              '${i['quantity']} × ${i['name']} · ${_moneyLabel(i['unitPriceMinor'], quoteSnapshot['currency'] as String? ?? 'KES')} each · ${i['priceSource']}',
        )
        .join('\n');
    final subtotal = quoteItems.fold<int>(
      0,
      (sum, item) =>
          sum +
          ((item['unitPriceMinor'] as int? ?? 0) *
              (item['quantity'] as int? ?? 1)),
    );
    return 'TOP HEIGHTS — PROJECT SUMMARY\n${_p['title']}\nStatus: ${_p['status']} (saved locally; not externally confirmed)\n'
        '${assessment.isEmpty ? '' : '\nASSESSMENT\n${assessment['name']} · ${assessmentPayload['property'] ?? 'Property not entered'} · ${assessmentPayload['useCase'] ?? 'Use case not entered'}\nDaily energy is a preliminary estimate based on the saved appliance inputs.'}'
        '${quote.isEmpty ? '' : '\n\nQUOTE · ${quote['title']} · version ${quote['current_version']}\nStatus: ${quote['status']} · pending business review\n${lines.isEmpty ? 'No catalogue lines saved.' : lines}\nItems subtotal: ${_moneyLabel(subtotal, quoteSnapshot['currency'] as String? ?? 'KES')}\nAssumptions: ${quoteSnapshot['assumptions'] ?? 'None entered'}\nValidity: ${quoteSnapshot['validUntil'] ?? 'Not entered'}'}'
        '\n\nMILESTONES\n${milestones.map((m) => '• ${m['title']}: ${m['state']}${((m['target_date'] as String?) ?? '').isEmpty ? '' : ' · target ${m['target_date']}'}').join('\n')}\n\nEVENT HISTORY\n${events.map((e) => '• ${e['created_at']}: ${e['summary']}').join('\n')}\n\nPreliminary record. Prices are unverified and no appointment or project status is confirmed unless explicitly marked by the business.';
  }

  @override
  Widget build(BuildContext context) {
    final milestones = (_p['milestones'] as List).cast<Map<String, Object?>>(),
        events = (_p['events'] as List).cast<Map<String, Object?>>(),
        docs = (_p['documents'] as List).cast<Map<String, Object?>>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_p['title'] as String),
        actions: [
          IconButton(
            tooltip: 'Share summary',
            onPressed: () => widget.onShare(_summary()),
            icon: const Icon(Icons.ios_share),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              await widget.repository.setProjectStatus(_p['id'] as String, v);
              await _refresh();
            },
            itemBuilder: (_) =>
                const ['Planned locally', 'Confirmed by business', 'On hold']
                    .map((s) => PopupMenuItem(value: s, child: Text('Set $s')))
                    .toList(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('PROJECT STATUS', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 5),
          Text('${_p['status']} · records stay on this device'),
          const SizedBox(height: 16),
          Text('MILESTONES', style: Theme.of(context).textTheme.titleMedium),
          for (final m in milestones)
            Card(
              child: ListTile(
                onTap: () => _edit(m),
                leading: Icon(
                  (m['state'] == 'Confirmed by business' ||
                          m['state'] == 'Complete')
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                  color: BrandColors.forest,
                ),
                title: Text(m['title'] as String),
                subtitle: Text(
                  '${m['state']}${((m['target_date'] as String?) ?? '').isEmpty ? '' : ' · ${m['target_date']}'}${((m['details'] as String?) ?? '').isEmpty ? '' : '\n${m['details']}'}',
                ),
                trailing: const Icon(Icons.edit_outlined),
              ),
            ),
          Text(
            'DOCUMENT CENTRE',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          OutlinedButton.icon(
            onPressed: _document,
            icon: const Icon(Icons.add),
            label: const Text('Add document record'),
          ),
          for (final d in docs)
            ListTile(
              dense: true,
              leading: const Icon(Icons.description_outlined),
              title: Text(d['name'] as String),
              subtitle: Text('${d['kind']} · ${d['reference']}'),
              trailing: IconButton(
                tooltip: 'Remove record',
                onPressed: () async {
                  await widget.repository.deleteDocument(d['id'] as String);
                  await _refresh();
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          const Divider(),
          Text('EVENT HISTORY', style: Theme.of(context).textTheme.titleMedium),
          for (final e in events)
            ListTile(
              dense: true,
              leading: const Icon(Icons.history, color: BrandColors.forest),
              title: Text(e['summary'] as String),
              subtitle: Text('${e['event_type']} · ${e['created_at']}'),
            ),
        ],
      ),
    );
  }
}
