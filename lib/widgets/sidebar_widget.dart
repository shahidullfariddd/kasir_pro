import 'package:flutter/material.dart';

class SidebarWidget extends StatelessWidget {
  final String activeMenu;

  const SidebarWidget({Key? key, required this.activeMenu}) : super(key: key);

  static final List<_SidebarMenu> sidebarMenus = [
    _SidebarMenu(icon: Icons.dashboard, title: "Dashboard", routeName: '/home'),
    _SidebarMenu(
      icon: Icons.admin_panel_settings,
      title: "Administrasi",
      routeName: '/administrasi',
    ),
    _SidebarMenu(
      icon: Icons.menu_book,
      title: "Katalog Menu",
      routeName: '/katalog_menu',
    ),
    _SidebarMenu(
      icon: Icons.shopping_cart,
      title: "Pemesanan",
      routeName: '/pemesanan',
    ),
    _SidebarMenu(
      icon: Icons.receipt_long,
      title: "Daftar Pesanan",
      routeName: '/daftar_pesanan',
    ),
    _SidebarMenu(
      icon: Icons.list_alt,
      title: "Catatan Belanja",
      routeName: '/catatan_belanja',
    ),
    _SidebarMenu(
      icon: Icons.person_outline,
      title: "Profile",
      routeName: '/profil',
    ),
  ];

  Widget buildSidebarItem(
    BuildContext context,
    IconData icon,
    String title,
    String? routeName,
  ) {
    bool isActive = title == activeMenu;

    return Container(
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F3FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.blue : Colors.grey[700]),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.blue : Colors.grey[800],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () async {
          if (title == "Logout") {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(
                      color: Color(0xFF1565C0),
                      width: 1.3,
                    ),
                  ),
                  elevation: 10,
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFE3F2FD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.logout,
                          color: Color(0xFF1565C0),
                          size: 45,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "Konfirmasi Logout",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Apakah Anda benar-benar ingin keluar?",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Color(0xFF1565C0),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text(
                                "Batal",
                                style: TextStyle(
                                  color: Color(0xFF1565C0),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                "Keluar",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

            if (confirm == true) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            }
          } else if (routeName != null) {
            Navigator.pushReplacementNamed(context, routeName);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lock_outline, color: Colors.blue, size: 28),
              SizedBox(width: 8),
              Text(
                "KasirPro",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          ...sidebarMenus.map(
            (menu) => buildSidebarItem(
              context,
              menu.icon,
              menu.title,
              menu.routeName,
            ),
          ),
          const Spacer(),
          const Divider(),
          buildSidebarItem(context, Icons.logout, "Logout", null),
        ],
      ),
    );
  }
}

class _SidebarMenu {
  final IconData icon;
  final String title;
  final String? routeName;

  const _SidebarMenu({required this.icon, required this.title, this.routeName});
}
