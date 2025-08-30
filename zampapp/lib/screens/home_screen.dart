import 'package:flutter/material.dart';
import 'adoption_screen.dart';
import 'donation_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Indice della pagina corrente, 0 = Adozioni

  // Lista delle tre schermate principali
  // Le classi AdoptionScreen, DonationScreen e ProfileScreen ora verranno trovate
  // grazie agli import corretti.
  static const List<Widget> _pages = <Widget>[
    AdoptionScreen(),
    DonationScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Il corpo della Scaffold mostra la pagina selezionata dalla lista
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      // Questa è la barra di navigazione in basso
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_outlined),
            activeIcon: Icon(Icons.pets),
            label: 'Adozioni',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.volunteer_activism_outlined),
            activeIcon: Icon(Icons.volunteer_activism),
            label: 'Donazioni',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profilo',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Funzione chiamata al tap su un'icona
      ),
    );
  }
}
