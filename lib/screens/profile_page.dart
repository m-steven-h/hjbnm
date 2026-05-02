import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../providers/theme_provider.dart';
import '../secrets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = 'مستخدم دقيقة صلاة';
  bool _isFounder = false;
  String _userId = '';
  String? _profileImage;
  final ImagePicker _picker = ImagePicker();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _requestRequiredPermissions();
  }

  Future<void> _requestRequiredPermissions() async {
    if (kIsWeb) return;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;

        if (androidInfo.version.sdkInt >= 33) {
          // Android 13+ يطلب فقط إذن الصور
          final status = await Permission.photos.request();
          if (status.isGranted) {
            print('✅ Photos permission granted');
          } else {
            print('❌ Photos permission denied');
          }
        } else {
          // Android 12 وأقل يطلب إذن التخزين
          final status = await Permission.storage.request();
          if (status.isGranted) {
            print('✅ Storage permission granted');
          } else {
            print('❌ Storage permission denied');
          }
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photos.request();
        if (status.isGranted) {
          print('✅ Photos permission granted');
        } else {
          print('❌ Photos permission denied');
        }
      }
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'مستخدم دقيقة صلاة';
      _userId = prefs.getString('userId') ?? '';
      _isFounder = _userId == Secrets.founderId;
      _profileImage = prefs.getString('profileImage');
    });
  }

  Future<void> _saveUserData(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await _loadUserData();
  }

  Future<void> _saveProfileImage(String? image) async {
    final prefs = await SharedPreferences.getInstance();
    if (image != null) {
      await prefs.setString('profileImage', image);
    } else {
      await prefs.remove('profileImage');
    }
    await _loadUserData();
  }

  Future<bool> _requestGalleryPermission() async {
    if (kIsWeb) return true;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;

        if (androidInfo.version.sdkInt >= 33) {
          // Android 13+
          final status = await Permission.photos.request();
          if (status.isGranted) {
            return true;
          } else if (status.isPermanentlyDenied) {
            _showPermissionDialog('الوصول إلى الصور');
            return false;
          }
          return false;
        } else {
          // Android 12 وأقل
          final status = await Permission.storage.request();
          if (status.isGranted) {
            return true;
          } else if (status.isPermanentlyDenied) {
            _showPermissionDialog('الوصول إلى التخزين');
            return false;
          }
          return false;
        }
      } else if (Platform.isIOS) {
        final status = await Permission.photos.request();
        if (status.isGranted) {
          return true;
        } else if (status.isPermanentlyDenied) {
          _showPermissionDialog('الوصول إلى الصور');
          return false;
        }
        return false;
      }

      return true;
    } catch (e) {
      print('Error requesting gallery permission: $e');
      return false;
    }
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;

    try {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        _showPermissionDialog('الكاميرا');
        return false;
      }
      return false;
    } catch (e) {
      print('Error requesting camera permission: $e');
      return false;
    }
  }

  void _showPermissionDialog(String permissionName) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('الأذونات مطلوبة'),
        content: Text('يرجى منح إذن $permissionName من إعدادات الجهاز'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              openAppSettings();
            },
            child: const Text('الإعدادات'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // طلب الإذن المناسب حسب المصدر
      bool hasPermission = false;

      if (source == ImageSource.camera) {
        hasPermission = await _requestCameraPermission();
      } else {
        hasPermission = await _requestGalleryPermission();
      }

      if (!hasPermission) {
        if (mounted) {
          _showErrorSnackBar(context, 'لا توجد أذونات كافية');
        }
        return;
      }

      // اختيار الصورة
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        String? imageData;

        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          imageData = base64Encode(bytes);
        } else {
          imageData = pickedFile.path;
        }

        await _saveProfileImage(imageData);
        if (mounted) {
          _showSuccessSnackBar(context, 'تم تحديث الصورة الشخصية');
        }
      }
    } on PlatformException catch (e) {
      print('PlatformException: $e');
      if (mounted) {
        _showErrorSnackBar(context, 'حدث خطأ في النظام: ${e.message}');
      }
    } catch (e) {
      print('General Error: $e');
      if (mounted) {
        _showErrorSnackBar(context, 'حدث خطأ أثناء اختيار الصورة');
      }
    }
  }

  Future<void> _showImagePickerDialog() async {
    final provider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: provider.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'اختر صورة الملف الشخصي',
            style: GoogleFonts.cairo(
              color: provider.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF4ADE80)),
                title: Text(
                  'التقاط صورة',
                  style: GoogleFonts.cairo(color: provider.textColor),
                ),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Color(0xFF4ADE80)),
                title: Text(
                  'اختيار من المعرض',
                  style: GoogleFonts.cairo(color: provider.textColor),
                ),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_profileImage != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    'حذف الصورة',
                    style: GoogleFonts.cairo(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _saveProfileImage(null);
                    _showSuccessSnackBar(context, 'تم حذف الصورة الشخصية');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    if (_profileImage == null || _profileImage!.isEmpty) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person,
          size: 50,
          color: Colors.white.withOpacity(0.8),
        ),
      );
    }

    if (kIsWeb) {
      try {
        final Uint8List bytes = base64Decode(_profileImage!);
        return ClipOval(
          child: Image.memory(
            bytes,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultAvatar();
            },
          ),
        );
      } catch (e) {
        return _buildDefaultAvatar();
      }
    } else {
      try {
        final file = File(_profileImage!);
        return FutureBuilder<bool>(
          future: file.exists(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data == true) {
              return ClipOval(
                child: Image.file(
                  file,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildDefaultAvatar();
                  },
                ),
              );
            } else {
              return _buildDefaultAvatar();
            }
          },
        );
      } catch (e) {
        return _buildDefaultAvatar();
      }
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: 50,
        color: Colors.white.withOpacity(0.8),
      ),
    );
  }

  Future<bool> _showSecretCodeDialog(BuildContext context) async {
    final TextEditingController codeController = TextEditingController();
    final completer = Completer<bool>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Consumer<ThemeProvider>(
        builder: (context, provider, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              backgroundColor: provider.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Color(0xFF4ADE80),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'تأكيد صلاحية المؤسس',
                    style: GoogleFonts.cairo(
                      color: provider.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'لتصبح مؤسساً، تحتاج إلى إدخال الكود السري',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: provider.secondaryTextColor,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: provider.backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF4ADE80).withOpacity(0.3),
                      ),
                    ),
                    child: TextFormField(
                      controller: codeController,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.ltr,
                      obscureText: true,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        color: provider.textColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'أدخل الكود السري',
                        hintStyle: GoogleFonts.cairo(
                          color: provider.secondaryTextColor.withOpacity(0.5),
                          fontSize: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final bool isValid = (codeController.text.trim() ==
                              Secrets.founderSecretCode);
                          if (!completer.isCompleted) {
                            completer.complete(isValid);
                          }
                          Navigator.pop(dialogContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4ADE80),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'تأكيد',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          if (!completer.isCompleted) {
                            completer.complete(false);
                          }
                          Navigator.pop(dialogContext);
                        },
                        child: Text(
                          'إلغاء',
                          style: GoogleFonts.cairo(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return completer.future;
  }

  Future<bool> _checkAndUpdateName(
      BuildContext context, String newName, String oldName) async {
    if (newName == oldName) {
      return false;
    }

    final bool isNewNameFounder = newName.trim() == 'M STEVEN H';
    final bool wasFounder = _isFounder;

    if (!wasFounder && isNewNameFounder) {
      final bool codeVerified = await _showSecretCodeDialog(context);
      if (codeVerified) {
        await _saveUserData(newName);
        await _loadUserData();
        _showSuccessSnackBar(context, 'تم تحديث الاسم وصلاحيات المؤسس');
        return true;
      } else {
        _showErrorSnackBar(context, 'الكود السري غير صحيح، لم يتم تحديث الاسم');
        return false;
      }
    } else if (wasFounder && !isNewNameFounder) {
      await _saveUserData(newName);
      await _loadUserData();
      _showSuccessSnackBar(context, 'تم تحديث الاسم (أصبحت مستخدم عادي)');
      return true;
    } else if (wasFounder && isNewNameFounder) {
      await _saveUserData(newName);
      await _loadUserData();
      _showSuccessSnackBar(context, 'تم تحديث الاسم');
      return true;
    } else {
      await _saveUserData(newName);
      await _loadUserData();
      _showSuccessSnackBar(context, 'تم تحديث الاسم');
      return true;
    }
  }

  void _showEditDialog(BuildContext context, ThemeProvider provider) {
    final TextEditingController controller =
        TextEditingController(text: _userName);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: provider.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              'تعديل الاسم',
              style: GoogleFonts.cairo(
                color: provider.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20 * provider.fontScale,
              ),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: controller,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: 16 * provider.fontScale,
                      color: provider.textColor,
                    ),
                    decoration: InputDecoration(
                      labelText: 'اسم المستخدم',
                      labelStyle: GoogleFonts.cairo(
                        color: provider.secondaryTextColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: const Color(0xFF4ADE80).withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: const Color(0xFF4ADE80).withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF4ADE80),
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال اسمك';
                      }
                      if (value.trim().length < 2) {
                        return 'الاسم قصير جداً';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final newName = controller.text.trim();
                          Navigator.pop(dialogContext);

                          Future.microtask(() async {
                            final success = await _checkAndUpdateName(
                              context,
                              newName,
                              _userName,
                            );
                            if (success && mounted) {
                              await _loadUserData();
                              setState(() {});
                            }
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4ADE80),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'حفظ',
                        style: GoogleFonts.cairo(
                          fontSize: 16 * provider.fontScale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        'إلغاء',
                        style: GoogleFonts.cairo(
                          fontSize: 16 * provider.fontScale,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: const Color(0xFF4ADE80),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, provider, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: provider.backgroundColor,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      _buildProfileCard(provider),
                      const SizedBox(height: 20),
                      _buildEditButton(provider),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(ThemeProvider provider) {
    final isFounder = _userId == Secrets.founderId;
    return GestureDetector(
      onTap: _showImagePickerDialog,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: isFounder
                ? [const Color(0xFF4ADE80), const Color(0xFF22C55E)]
                : [const Color(0xFF4ADE80), const Color(0xFF22C55E)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4ADE80).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Stack(
                children: [
                  _buildProfileAvatar(),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Color(0xFF4ADE80),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _userName,
                style: GoogleFonts.cairo(
                  fontSize: 28 * provider.fontScale,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isFounder ? 'مؤسس التطبيق' : 'مستخدم دقيقة صلاة',
                  style: GoogleFonts.cairo(
                    fontSize: 14 * provider.fontScale,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditButton(ThemeProvider provider) {
    return GestureDetector(
      onTap: () => _showEditDialog(context, provider),
      child: Container(
        decoration: BoxDecoration(
          color: provider.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF4ADE80).withOpacity(0.15),
                      const Color(0xFF4ADE80).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFF4ADE80),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'تعديل اسم المستخدم',
                  style: GoogleFonts.cairo(
                    fontSize: 18 * provider.fontScale,
                    fontWeight: FontWeight.w600,
                    color: provider.textColor,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: const Color(0xFF4ADE80),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
