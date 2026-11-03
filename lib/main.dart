import 'package:flutter/material.dart';

void main() => runApp(const CampusFlowApp());

// ---------------------------------------------------------------
// Modèle
// ---------------------------------------------------------------
class Echeance {
  Echeance({
    required this.titre,
    required this.matiere,
    required this.date,
    this.description = '',
    this.fait = false,
  });

  String titre;
  String matiere;
  DateTime date;
  String description;
  bool fait;
}

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

// ---------------------------------------------------------------
// App
// ---------------------------------------------------------------
class CampusFlowApp extends StatelessWidget {
  const CampusFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.red,
      ),
      home: const EcheancesPage(),
    );
  }
}

// ---------------------------------------------------------------
// TÂCHE 1 + 4 : Écran Échéances (liste) + version tablette
// ---------------------------------------------------------------
class EcheancesPage extends StatefulWidget {
  const EcheancesPage({super.key});

  @override
  State<EcheancesPage> createState() => _EcheancesPageState();
}

class _EcheancesPageState extends State<EcheancesPage> {
  int _tab = 0; // 0 = à faire, 1 = terminées
  Echeance? _selected;

  final List<Echeance> _items = [
    Echeance(
      titre: 'Rapport de TP Réseaux',
      matiere: 'Réseaux',
      date: DateTime.now().add(const Duration(days: 2)),
      description: 'Rendre le rapport PDF avec les captures Packet Tracer.',
    ),
    Echeance(
      titre: 'Examen Traitement du signal',
      matiere: 'Signal',
      date: DateTime.now().add(const Duration(days: 6)),
      description: 'Chapitres 1 à 4. Revoir la transformée de Fourier.',
    ),
    Echeance(
      titre: 'Séance de tutorat',
      matiere: 'Tutorat',
      date: DateTime.now().add(const Duration(days: 1)),
    ),
  ];

  List<Echeance> get _visibles {
    final l = _items.where((e) => e.fait == (_tab == 1)).toList();
    l.sort((a, b) => a.date.compareTo(b.date));
    return l;
  }

  void _toggle(Echeance e) {
    setState(() {
      e.fait = !e.fait;
      _selected = null;
    });
  }

  Future<void> _ajouter() async {
    final result = await Navigator.push<Echeance>(
      context,
      MaterialPageRoute(builder: (_) => const FormulairePage()),
    );
    if (result != null && mounted) {
      setState(() => _items.add(result));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('« ${result.titre} » ajoutée')),
      );
    }
  }

  Future<void> _modifier(Echeance e) async {
    final result = await Navigator.push<Echeance>(
      context,
      MaterialPageRoute(builder: (_) => FormulairePage(initial: e)),
    );
    if (result != null && mounted) {
      setState(() {
        e.titre = result.titre;
        e.matiere = result.matiere;
        e.date = result.date;
        e.description = result.description;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('« ${e.titre} » modifiée')),
      );
    }
  }

  void _ouvrirDetail(Echeance e, bool large) {
    if (large) {
      setState(() => _selected = e);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => Scaffold(
            appBar: AppBar(title: const Text('Détail')),
            body: DetailView(
              echeance: e,
              onToggle: () {
                _toggle(e);
                Navigator.pop(ctx);
              },
              onEdit: () async {
                Navigator.pop(ctx);
                await _modifier(e);
              },
            ),
          ),
        ),
      );
    }
  }

  Widget _liste(bool large) {
    final data = _visibles;
    if (data.isEmpty) {
      return const Center(child: Text('Aucune échéance ici.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 88),
      itemCount: data.length,
      itemBuilder: (context, i) {
        final e = data[i];
        final selected = large && e == _selected;
        final scheme = Theme.of(context).colorScheme;
        return Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outline,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: ListTile(
            leading: Icon(
              e.fait ? Icons.check_circle : Icons.schedule,
              color: e.fait ? Colors.green : null,
            ),
            title: Text(e.titre),
            subtitle: Text('${e.matiere} · ${formatDate(e.date)}'),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifier',
              onPressed: () => _modifier(e),
            ),
            selected: selected,
            onTap: () => _ouvrirDetail(e, large),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // TÂCHE 4 : LayoutBuilder à 840 dp
    return LayoutBuilder(
      builder: (context, constraints) {
        final large = constraints.maxWidth >= 840;
        return Scaffold(
          appBar: AppBar(title: const Text('CampusFlow')),
          body: large
              ? Row(
            children: [
              SizedBox(width: 380, child: _liste(true)),
              const VerticalDivider(width: 1),
              Expanded(
                child: _selected == null
                    ? const Center(
                    child: Text('Sélectionne une échéance'))
                    : DetailView(
                  echeance: _selected!,
                  onToggle: () => _toggle(_selected!),
                  onEdit: () => _modifier(_selected!),
                ),
              ),
            ],
          )
              : _liste(false),
          floatingActionButton: FloatingActionButton(
            onPressed: _ajouter,
            tooltip: 'Ajouter une échéance',
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() {
              _tab = i;
              _selected = null;
            }),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.event_outlined),
                selectedIcon: Icon(Icons.event),
                label: 'À faire',
              ),
              NavigationDestination(
                icon: Icon(Icons.task_alt_outlined),
                selectedIcon: Icon(Icons.task_alt),
                label: 'Terminées',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------
// TÂCHE 2 : Écran Détail
// ---------------------------------------------------------------
class DetailView extends StatelessWidget {
  const DetailView({
    super.key,
    required this.echeance,
    required this.onToggle,
    required this.onEdit,
  });

  final Echeance echeance;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final e = echeance;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: Theme.of(context).colorScheme.outline, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.titre,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Matière : ${e.matiere}'),
                  Text('Date limite : ${formatDate(e.date)}'),
                  const SizedBox(height: 12),
                  Text(e.description.isEmpty
                      ? 'Aucune description.'
                      : e.description),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onToggle,
            icon: Icon(e.fait ? Icons.undo : Icons.check),
            label: Text(e.fait ? 'Remettre à faire' : 'Marquer comme fait'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Modifier'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------
// TÂCHE 3 : Formulaire
// ---------------------------------------------------------------
class FormulairePage extends StatefulWidget {
  const FormulairePage({super.key, this.initial});

  /// Si non nul, le formulaire est en mode modification.
  final Echeance? initial;

  @override
  State<FormulairePage> createState() => _FormulairePageState();
}

class _FormulairePageState extends State<FormulairePage> {
  final _formKey = GlobalKey<FormState>();
  final _titre = TextEditingController();
  final _matiere = TextEditingController();
  final _description = TextEditingController();
  final _dateCtrl = TextEditingController();
  DateTime? _date;

  bool get _edition => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    if (e != null) {
      _titre.text = e.titre;
      _matiere.text = e.matiere;
      _description.text = e.description;
      _date = e.date;
      _dateCtrl.text = formatDate(e.date);
    }
  }

  @override
  void dispose() {
    _titre.dispose();
    _matiere.dispose();
    _description.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: (_date != null && _date!.isBefore(now))
          ? _date!
          : now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (d != null) {
      setState(() {
        _date = d;
        _dateCtrl.text = formatDate(d);
      });
    }
  }

  void _enregistrer() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(
        context,
        Echeance(
          titre: _titre.text.trim(),
          matiere: _matiere.text.trim(),
          date: _date!,
          description: _description.text.trim(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrige les champs en erreur')),
      );
    }
  }

  String? _requis(String? v, String champ) =>
      (v == null || v.trim().isEmpty) ? '$champ est requis' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_edition ? 'Modifier l\'échéance' : 'Nouvelle échéance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titre,
                decoration: const InputDecoration(
                    labelText: 'Titre', border: OutlineInputBorder()),
                validator: (v) => _requis(v, 'Le titre'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _matiere,
                decoration: const InputDecoration(
                    labelText: 'Matière', border: OutlineInputBorder()),
                validator: (v) => _requis(v, 'La matière'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateCtrl,
                readOnly: true,
                onTap: _choisirDate,
                decoration: const InputDecoration(
                  labelText: 'Date limite',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                validator: (v) => _requis(v, 'La date'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Description (optionnel)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _enregistrer,
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}