import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../blocs/topup/topup_bloc.dart';
import '../../blocs/topup/topup_event.dart';
import '../../blocs/topup/topup_state.dart';
import '../../blocs/wallet/wallet_bloc.dart';
import '../../blocs/wallet/wallet_event.dart';
import '../../widgets/money_input_sheet.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _amountController = TextEditingController();
  int _step = 1;
  File? _proofImage;
  final _picker = ImagePicker();

  String formatRupiah(double val) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(val);
  }

  @override
  void initState() {
    super.initState();
    context.read<TopUpBloc>().add(FetchPaymentMethods());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _proofImage = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1b35),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f1b35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_step > 1) {
              setState(() {
                _step--;
                if (_step == 1) _proofImage = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _step == 1
              ? 'Top Up KyPay'
              : _step == 2
              ? 'Detail Top Up'
              : 'Pengajuan Terkirim',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: _step < 3
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: _step / 2,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF1a56db)),
                ),
              )
            : null,
      ),
      body: BlocListener<TopUpBloc, TopUpState>(
        listener: (context, state) {
          if (state is TopUpSuccess) {
            context.read<WalletBloc>().add(FetchWallet());
            setState(() => _step = 3);
          } else if (state is TopUpError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_step == 1) return _buildStep1();
    if (_step == 2) return _buildStep2();
    return _buildStep3();
  }

  // ── Step 1: Pilih Metode ─────────────────────────────────────────────────
  Widget _buildStep1() {
    return BlocBuilder<TopUpBloc, TopUpState>(
      builder: (context, state) {
        if (state is TopUpMethodsLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1a56db)),
          );
        }

        if (state is TopUpMethodsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  state.message,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      context.read<TopUpBloc>().add(FetchPaymentMethods()),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        if (state is TopUpMethodsLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    //ignore: deprecated_member_use
                    color: const Color(0xFF1a56db).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    //ignore: deprecated_member_use
                    border: Border.all(
                      // ignore: deprecated_member_use
                      color: const Color(0xFF1a56db).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF1a56db),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pilih metode pembayaran. Admin akan memverifikasi bukti transfer kamu.',
                          //ignore: deprecated_member_use
                          style: TextStyle(
                            // ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Pilih Metode Pembayaran',
                  style: TextStyle(
                    //ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 12),

                if (state.methods.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        'Belum ada metode pembayaran tersedia',
                        //ignore: deprecated_member_use
                        style: TextStyle(color: Colors.white.withOpacity(0.4)),
                      ),
                    ),
                  )
                else
                  ...state.methods.map((method) {
                    final isSelected =
                        state.selectedMethod != null &&
                        state.selectedMethod!['id'] == method['id'];
                    return GestureDetector(
                      onTap: () => context.read<TopUpBloc>().add(
                        SelectPaymentMethod(method),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              //ignore: deprecated_member_use
                              ? const Color(0xFF1a56db).withOpacity(0.15)
                              //ignore: deprecated_member_use
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1a56db)
                                //ignore: deprecated_member_use
                                : Colors.white.withOpacity(0.1),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                //ignore: deprecated_member_use
                                color: const Color(0xFF1a56db).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: method['logo'] != null
                                    ? Image.network(
                                        method['logo'] as String,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.account_balance,
                                                color: Color(0xFF1a56db),
                                                size: 22,
                                              );
                                            },
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return const Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Color(0xFF1a56db)),
                                                  ),
                                                ),
                                              );
                                            },
                                      )
                                    : const Icon(
                                        Icons.account_balance,
                                        color: Color(0xFF1a56db),
                                        size: 22,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    method['name'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${method['account_number'] ?? ''} • ${method['account_name'] ?? ''}',
                                    style: TextStyle(
                                      //ignore: deprecated_member_use
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (method['min_amount'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Min. ${formatRupiah(double.tryParse(method['min_amount'].toString()) ?? 0)}',
                                      style: TextStyle(
                                        //ignore: deprecated_member_use
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF1a56db),
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: state.selectedMethod == null
                        ? null
                        : () => setState(() => _step = 2),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1a56db),
                      disabledBackgroundColor: Colors.white12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      state.selectedMethod == null
                          ? 'Pilih metode dulu'
                          : 'Lanjut',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox();
      },
    );
  }

  // ── Step 2: Input Jumlah + Upload Bukti ─────────────────────────────────
  Widget _buildStep2() {
    return BlocBuilder<TopUpBloc, TopUpState>(
      builder: (context, state) {
        Map<String, dynamic>? method;
        if (state is TopUpMethodsLoaded) method = state.selectedMethod;
        if (state is TopUpSubmitting) method = state.selectedMethod;

        final isSubmitting = state is TopUpSubmitting;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info metode terpilih
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  //ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  //ignore: deprecated_member_use
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        //ignore: deprecated_member_use
                        color: const Color(0xFF1a56db).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: method != null && method['logo'] != null
                            ? Image.network(
                                method['logo'] as String,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.account_balance,
                                    color: Color(0xFF1a56db),
                                    size: 20,
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF1a56db),
                                                ),
                                          ),
                                        ),
                                      );
                                    },
                              )
                            : const Icon(
                                Icons.account_balance,
                                color: Color(0xFF1a56db),
                                size: 20,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method != null ? method['name'] ?? '' : '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            method != null
                                ? '${method['account_number'] ?? ''} a.n ${method['account_name'] ?? ''}'
                                : '',
                            style: TextStyle(
                              //ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Input jumlah
              Text(
                'Jumlah Top Up',
                style: TextStyle(
                  //ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: isSubmitting
                    ? null
                    : () async {
                        final result = await showMoneyInput(
                          context,
                          title: 'Jumlah Top Up',
                          maxValue: null,
                          quickAmounts: [
                            50000,
                            100000,
                            200000,
                            500000,
                            1000000,
                            2000000,
                          ],
                          accentColor: const Color(0xFF1a56db),
                        );
                        if (result != null) {
                          setState(
                            () => _amountController.text = result
                                .toInt()
                                .toString(),
                          );
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    //ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(
                      //ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.1),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rp ',
                            style: TextStyle(
                              //ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _amountController.text.isEmpty
                                ? '0'
                                : formatRupiah(
                                    double.tryParse(_amountController.text) ??
                                        0,
                                  ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        isSubmitting ? Icons.check_circle : Icons.edit_outlined,
                        color: const Color(0xFF1a56db),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Upload bukti
              Text(
                'Upload Bukti Transfer',
                style: TextStyle(
                  //ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: isSubmitting ? null : _pickImage,
                child: Container(
                  width: double.infinity,
                  height: _proofImage != null ? 200 : 120,
                  decoration: BoxDecoration(
                    //ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _proofImage != null
                          //ignore: deprecated_member_use
                          ? Colors.green.withOpacity(0.5)
                          //ignore: deprecated_member_use
                          : Colors.white.withOpacity(0.15),
                    ),
                  ),
                  child: _proofImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_proofImage!, fit: BoxFit.cover),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _proofImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              //ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.3),
                              size: 36,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap untuk upload bukti transfer',
                              style: TextStyle(
                                //ignore: deprecated_member_use
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'JPG, PNG (maks. 2MB)',
                              style: TextStyle(
                                //ignore: deprecated_member_use
                                color: Colors.white.withOpacity(0.25),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  //ignore: deprecated_member_use
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      //ignore: deprecated_member_use
                      Border.all(color: Colors.amber.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pengajuan akan diverifikasi admin dalam 1x24 jam.',
                        style: TextStyle(
                          //ignore: deprecated_member_use
                          color: Colors.amber.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1a56db),
                    disabledBackgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Kirim Pengajuan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Step 3: Sukses ───────────────────────────────────────────────────────
  Widget _buildStep3() {
    return BlocBuilder<TopUpBloc, TopUpState>(
      builder: (context, state) {
        final success = state is TopUpSuccess ? state : null;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    //ignore: deprecated_member_use
                    color: Colors.green.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      //ignore: deprecated_member_use
                      color: Colors.green.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pengajuan Terkirim!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  success != null ? formatRupiah(success.amount) : '',
                  style: const TextStyle(
                    color: Color(0xFF1a56db),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'via ${success?.methodName ?? ''}',
                  style: TextStyle(
                    //ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    //ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        //ignore: deprecated_member_use
                        Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tag,
                        //ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.4),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ref: ${success?.referenceNumber ?? '-'}',
                        style: TextStyle(
                          //ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Admin akan memverifikasi bukti transfer kamu.\nSaldo akan ditambahkan setelah disetujui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    //ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<TopUpBloc>().add(ResetTopUp());
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1a56db),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Kembali ke Wallet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    final amount =
        double.tryParse(
          _amountController.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0;

    if (amount < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal top up Rp 10.000'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload bukti transfer dulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final state = context.read<TopUpBloc>().state;
    Map<String, dynamic>? selectedMethod;
    if (state is TopUpMethodsLoaded && state.selectedMethod != null) {
      selectedMethod = state.selectedMethod;
    }

    if (selectedMethod == null) return;

    context.read<TopUpBloc>().add(
      SubmitTopUp(
        amount: amount,
        paymentMethod: selectedMethod['name'] ?? '',
        paymentAccount: selectedMethod['account_number'] ?? '',
        paymentHolder: selectedMethod['account_name'] ?? '',
        imagePath: _proofImage!.path,
      ),
    );
  }
}
