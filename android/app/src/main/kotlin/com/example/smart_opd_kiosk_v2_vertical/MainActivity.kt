package com.example.smart_opd_kiosk_v2_vertical

import android.app.PendingIntent
import android.content.*
import android.hardware.usb.*
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "thai_id_reader"

    private var readingCard = false

    private lateinit var channel: MethodChannel

    private lateinit var usbManager: UsbManager

    private var pendingDevice: UsbDevice? = null

    private val ACTION_USB_PERMISSION = "com.example.smart_opd_kiosk_v2_vertical.USB_PERMISSION"

    private var cardPresent = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {

        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startReader" -> {

                    Log.d("USB_TEST", "START READER")

                    sendLog("START READER")

                    startUsbReader()

                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    // ---------------- USB Receiver ----------------

    private val usbReceiver =
            object : BroadcastReceiver() {

                override fun onReceive(context: Context, intent: Intent) {

                    Log.d("USB_TEST", "RECEIVER ACTION = ${intent.action}")

                    when (intent.action) {
                        ACTION_USB_PERMISSION -> {
                            val device =
                                    intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)
                            val granted =
                                    intent.getBooleanExtra(
                                            UsbManager.EXTRA_PERMISSION_GRANTED,
                                            false
                                    )

                            if (granted) {
                                Log.d("USB_TEST", "Permission GRANTED")
                                sendLog("Permission GRANTED")
                                device?.let {
                                    // สำคัญมาก: สั่งเปิดเครื่องอ่านทันทีที่ผู้ใช้กด "ตกลง"
                                    openSmartCard(it)
                                }
                            } else {
                                Log.d("USB_TEST", "Permission DENIED")
                                sendLog("Permission DENIED")
                            }
                        }
                        UsbManager.ACTION_USB_DEVICE_ATTACHED -> {

                            val device =
                                    intent.getParcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)

                            Log.d("USB_TEST", "USB DEVICE ATTACHED")

                            device?.let {
                                val intentPermission = Intent(ACTION_USB_PERMISSION)

                                intentPermission.setPackage(packageName)

                                val permissionIntent =
                                        PendingIntent.getBroadcast(
                                                this@MainActivity,
                                                0,
                                                intentPermission,
                                                PendingIntent.FLAG_UPDATE_CURRENT or
                                                        PendingIntent.FLAG_IMMUTABLE
                                        )

                                usbManager.requestPermission(it, permissionIntent)
                            }
                        }
                        UsbManager.ACTION_USB_DEVICE_DETACHED -> {

                            Log.d("USB_TEST", "USB DEVICE REMOVED")

                            cardPresent = false
                        }
                    }
                }
            }

    // ---------------- Start Reader ----------------

    private fun startUsbReader() {
        usbManager = getSystemService(Context.USB_SERVICE) as UsbManager

        // ลงทะเบียน Receiver (ทำเหมือนเดิม)
        val filter =
                IntentFilter().apply {
                    addAction(ACTION_USB_PERMISSION)
                    addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
                    addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
                }
        // ... ลงทะเบียน receiver ตามเวอร์ชัน Android ...

        val deviceList = usbManager.deviceList
        if (deviceList.isEmpty()) {
            sendLog("No USB Device Found")
            return
        }

        for (device in deviceList.values) {
            Log.d("USB_TEST", "Device Found: ${device.deviceName}")
            if (usbManager.hasPermission(device)) {
                sendLog("Already has permission")
                openSmartCard(device)
            } else {
                Log.d("USB_TEST", "No permission, requesting now...")
                val intentPermission =
                        Intent(ACTION_USB_PERMISSION).apply { setPackage(packageName) }
                val permissionIntent =
                        PendingIntent.getBroadcast(
                                this,
                                0,
                                intentPermission,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        )
                usbManager.requestPermission(device, permissionIntent)
                // ไม่ต้องเรียก openSmartCard ตรงนี้ เพราะสิทธิ์ยังไม่มี
                // ให้รอไปเข้าที่ usbReceiver แทน
            }
            break // ถ้ามีหลายเครื่อง เอาแค่เครื่องแรกก่อน
        }
    }

    // ---------------- Open SmartCard ----------------

    private fun openSmartCard(device: UsbDevice) {

        val usbInterface = device.getInterface(0)

        val connection = usbManager.openDevice(device)

        if (connection == null) {

            Log.d("USB_TEST", "Open Device Failed")

            return
        }

        connection.claimInterface(usbInterface, true)

        var endpointIn: UsbEndpoint? = null

        var endpointOut: UsbEndpoint? = null

        for (i in 0 until usbInterface.endpointCount) {

            val ep = usbInterface.getEndpoint(i)

            if (ep.type == UsbConstants.USB_ENDPOINT_XFER_BULK) {

                if (ep.direction == UsbConstants.USB_DIR_IN) endpointIn = ep else endpointOut = ep
            }
        }

        if (endpointIn == null || endpointOut == null) {

            Log.d("USB_TEST", "Endpoint Not Found")

            return
        }

        startCardMonitor(connection, endpointIn, endpointOut)
    }

    // ---------------- Monitor Card ----------------

    private fun startCardMonitor(
            connection: UsbDeviceConnection,
            endpointIn: UsbEndpoint,
            endpointOut: UsbEndpoint
    ) {

        Thread {
                    while (true) {

                        if (readingCard) {
                            Thread.sleep(300)
                            continue
                        }

                        val status = getSlotStatus(connection, endpointIn, endpointOut)

                        when (status) {
                            1 -> {

                                if (!cardPresent) {

                                    cardPresent = true

                                    Log.d("USB_TEST", "CARD INSERTED")

                                    sendLog("CARD INSERTED")

                                    powerOnCard(connection, endpointIn, endpointOut)
                                }
                            }
                            2 -> { // ช่องว่าง (ไม่มีบัตร)
                                if (cardPresent) {
                                    cardPresent = false
                                    Log.d("USB_TEST", "CARD REMOVED")
                                    
                                    // ส่ง event แจ้ง Flutter ว่าบัตรถูกดึงออกแล้ว
                                    runOnUiThread { 
                                        channel.invokeMethod("onCardRemoved", null)
                                        sendLog("CARD REMOVED") 
                                    }
                                }
                            }
                        }

                        Thread.sleep(700)
                    }
                }
                .start()
    }

    // ---------------- Slot Status ----------------

    private fun getSlotStatus(
            connection: UsbDeviceConnection,
            endpointIn: UsbEndpoint,
            endpointOut: UsbEndpoint
    ): Int {

        val cmd = byteArrayOf(0x65.toByte(), 0, 0, 0, 0, 0, 1, 0, 0, 0)

        connection.bulkTransfer(endpointOut, cmd, cmd.size, 1000)

        val buffer = ByteArray(64)

        val len = connection.bulkTransfer(endpointIn, buffer, buffer.size, 1000)

        if (len > 0) {

            return buffer[7].toInt() and 0x03
        }

        return 2
    }

    private fun powerOnCard(
            connection: UsbDeviceConnection,
            endpointIn: UsbEndpoint,
            endpointOut: UsbEndpoint
    ) {

        Thread {

                    // CCID: PC_to_RDR_IccPowerOn

                    val powerOnCmd =
                            byteArrayOf(
                                    0x62.toByte(),
                                    0x00,
                                    0x00,
                                    0x00,
                                    0x00,
                                    0x00,
                                    0x01,
                                    0x00,
                                    0x00,
                                    0x00
                            )

                    connection.bulkTransfer(endpointOut, powerOnCmd, powerOnCmd.size, 1000)

                    val buffer = ByteArray(256)

                    val len = connection.bulkTransfer(endpointIn, buffer, buffer.size, 2000)

                    if (len > 0) {

                        readingCard = true

                        val atr = buffer.take(len).joinToString(" ") { "%02X".format(it) }

                        Log.d("USB_TEST", "ATR: $atr")

                        sendLog("ATR Received")

                        // เมื่อ Power On สำเร็จ ให้ไปขั้นตอนอ่านข้อมูล

                        readThaiCard(connection, endpointIn, endpointOut)

                         readingCard = false
                    } else {

                        sendLog("Power On Failed")
                    }
                }
                .start()
    }

    // ---------------- Read Thai Card ----------------

    private fun sendApdu(
            connection: UsbDeviceConnection,
            endpointIn: UsbEndpoint,
            endpointOut: UsbEndpoint,
            apdu: ByteArray,
            seq: Byte
    ): ByteArray? {

        val header =
                byteArrayOf(
                        0x6F.toByte(),
                        (apdu.size and 0xff).toByte(),
                        0x00,
                        0x00,
                        0x00,
                        0x00, // Slot
                        seq, // Sequence
                        0x00,
                        0x00,
                        0x00 // Reserved
                )

        val command = header + apdu

        connection.bulkTransfer(endpointOut, command, command.size, 2000)

        val response = ByteArray(1024)

        val len = connection.bulkTransfer(endpointIn, response, response.size, 2000)

        // ตรวจสอบว่ามีข้อมูลกลับมา (อย่างน้อยต้องมี CCID Header 10 bytes + Status 2 bytes)

        if (len >= 12) {

            // ดึงความยาวข้อมูลจริงจาก CCID Header (ไบต์ที่ 1-4)

            val dataLen = (response[1].toInt() and 0xff)

            // Status Word (2 ไบต์สุดท้ายของข้อมูลทั้งหมด)

            val sw1 = response[len - 2].toInt() and 0xff

            val sw2 = response[len - 1].toInt() and 0xff

            Log.d("USB_TEST", "Seq: $seq, SW: ${"%02X %02X".format(sw1, sw2)}, DataLen: $dataLen")

            // ตัดเอาเฉพาะเนื้อข้อมูล (เริ่มจากไบต์ที่ 10 เป็นต้นไป)

            // val dataPart = response.sliceArray(10 until 10 + dataLen)
            val dataPart = response.sliceArray(10 until len - 2)

            if (sw1 == 0x90 && sw2 == 0x00) {

                return dataPart
            } else if (sw1 == 0x61) {

                // บัตรบอกให้ Get Response (ส่ง 00 C0 00 00 [sw2])

                val getResponseApdu =
                        byteArrayOf(
                                0x00.toByte(),
                                0xC0.toByte(),
                                0x00.toByte(),
                                0x00.toByte(),
                                sw2.toByte()
                        )

                return sendApdu(
                        connection,
                        endpointIn,
                        endpointOut,
                        getResponseApdu,
                        (seq + 1).toByte()
                )
           } else {
                // ADD THIS LOG:
                Log.e("USB_TEST", "APDU Failed with SW: ${"%02X %02X".format(sw1, sw2)}")
            }
        }

        return null
    }

   private fun readPhoto(
    connection: UsbDeviceConnection,
    endpointIn: UsbEndpoint,
    endpointOut: UsbEndpoint
): ByteArray? {
    val photoData = mutableListOf<Byte>()
    var seq: Byte = 0x20
    
    // ตำแหน่งเริ่มต้นของรูปภาพในบัตรไทยคือ 0x017B
    var offset = 0x017B 
    val blockSize = 0xFF // อ่านทีละ 255 ไบต์ (สูงสุดที่บัตรรับได้ต่อครั้ง)

    Log.d("USB_TEST", "Starting photo read at offset $offset...")

    while (true) {
        val p1 = ((offset shr 8) and 0xFF).toByte()
        val p2 = (offset and 0xFF).toByte()

        // APDU Command สำหรับ Read Binary
        val cmd = byteArrayOf(
            0x80.toByte(),
            0xB0.toByte(),
            p1,
            p2,
            0x02.toByte(), // ตัวบ่งชี้พิเศษสำหรับบาง Applet
            0x00.toByte(),
            blockSize.toByte()
        )

        val response = sendApdu(connection, endpointIn, endpointOut, cmd, seq++)

        if (response != null && response.isNotEmpty()) {
            photoData.addAll(response.toList())
            
            // ตรวจหาจุดสิ้นสุดของไฟล์ JPEG (FF D9)
            if (photoData.size >= 2) {
                for (i in 0 until photoData.size - 1) {
                    if ((photoData[i].toInt() and 0xFF) == 0xFF && 
                        (photoData[i + 1].toInt() and 0xFF) == 0xD9) {
                        
                        Log.d("USB_TEST", "JPEG End Marker found at ${i + 1}. Total size: ${i + 2}")
                        // ตัดเอาเฉพาะข้อมูลถึงจุดสิ้นสุด JPEG
                        return photoData.take(i + 2).toByteArray()
                    }
                }
            }

            // ถ้ายังไม่เจอ ให้เลื่อน offset ไปอ่านชุดถัดไป
            offset += blockSize
            
            // Safety break: ป้องกัน Loop ค้างถ้าบัตรมีปัญหา (ปกติรูปไม่เกิน 5KB)
            if (offset > 6000) {
                Log.e("USB_TEST", "Photo too large or EOF not found. Stopping.")
                break
            }
        } else {
            Log.e("USB_TEST", "Failed to read photo chunk at offset $offset")
            break
        }
    }

    return if (photoData.isNotEmpty()) photoData.toByteArray() else null
}

    private fun readThaiCard(
            connection: UsbDeviceConnection,
            endpointIn: UsbEndpoint,
            endpointOut: UsbEndpoint
    ) {

        try {

            val dataMap = mutableMapOf<String, Any>()

            // 1. Select Applet

            val selectApplet =
                    byteArrayOf(
                            0x00.toByte(),
                            0xA4.toByte(),
                            0x04.toByte(),
                            0x00.toByte(),
                            0x08.toByte(),
                            0xA0.toByte(),
                            0x00.toByte(),
                            0x00.toByte(),
                            0x00.toByte(),
                            0x54.toByte(),
                            0x48.toByte(),
                            0x00.toByte(),
                            0x01.toByte()
                    )

            sendApdu(connection, endpointIn, endpointOut, selectApplet, 0x01)

            // คำสั่งอ่านข้อมูลต่างๆ (P1, P2 สำหรับตำแหน่งข้อมูล)

            val commands =
                    mapOf(
                            "cid" to
                                    byteArrayOf(
                                            0x80.toByte(),
                                            0xb0.toByte(),
                                            0x00.toByte(),
                                            0x04.toByte(),
                                            0x02.toByte(),
                                            0x00.toByte(),
                                            0x0d.toByte()
                                    ),
                            "nameTH" to
                                    byteArrayOf(
                                            0x80.toByte(),
                                            0xb0.toByte(),
                                            0x00.toByte(),
                                            0x11.toByte(),
                                            0x02.toByte(),
                                            0x00.toByte(),
                                            0x64.toByte()
                                    ),
                            "nameEN" to
                                    byteArrayOf(
                                            0x80.toByte(),
                                            0xb0.toByte(),
                                            0x00.toByte(),
                                            0x75.toByte(),
                                            0x02.toByte(),
                                            0x00.toByte(),
                                            0x64.toByte()
                                    ),
                            "birthDate" to
                                    byteArrayOf(
                                            0x80.toByte(),
                                            0xb0.toByte(),
                                            0x00.toByte(),
                                            0xD9.toByte(),
                                            0x02.toByte(),
                                            0x00.toByte(),
                                            0x08.toByte()
                                    ),
                            "gender" to
                                    byteArrayOf(
                                            0x80.toByte(),
                                            0xb0.toByte(),
                                            0x00.toByte(),
                                            0xE1.toByte(),
                                            0x02.toByte(),
                                            0x00.toByte(),
                                            0x01.toByte()
                                    ),
                            "issueDate" to
                                    byteArrayOf(
                                            0x80.toByte(),
                                            0xb0.toByte(),
                                            0x01.toByte(),
                                            0x67.toByte(),
                                            0x02.toByte(),
                                            0x00.toByte(),
                                            0x08.toByte()
                                    ),
                            "expireDate" to
                                    byteArrayOf(
                                            0x80.toByte(),
                                            0xb0.toByte(),
                                            0x01.toByte(),
                                            0x6F.toByte(),
                                            0x02.toByte(),
                                            0x00.toByte(),
                                            0x08.toByte()
                                    ),
                            "address" to
                                    byteArrayOf(
                                            0x80.toByte(),
                                            0xb0.toByte(),
                                            0x15.toByte(),
                                            0x79.toByte(),
                                            0x02.toByte(),
                                            0x00.toByte(),
                                            0x64.toByte()
                                    )
                    )

            var seq = 0x03.toByte()

            for ((key, cmd) in commands) {

                val response = sendApdu(connection, endpointIn, endpointOut, cmd, seq)

                response?.let {
                    val rawString =
                            if (key == "cid" ||
                                            key == "birthDate" ||
                                            key == "issueDate" ||
                                            key == "expireDate"
                            ) {

                                String(it, Charsets.US_ASCII)
                            } else {

                                String(it, charset("TIS-620"))
                            }


                    val cleanData = rawString.replace("#", " ").trim()

                    dataMap[key] = cleanData
                }

                seq = (seq + 2).toByte()
            }

            // --- เพิ่มส่วนนี้เพื่ออ่านรูปภาพ ---
            sendLog("Reading Photo... Please wait (takes ~5-10s)")
            val photo = readPhoto(connection, endpointIn, endpointOut)
            if (photo != null) {
                dataMap["photoBytes"] = photo
                sendLog("Photo Read Success: ${photo.size} bytes")
            }

            // ส่งกลับ Flutter ทั้งก้อน

            if (dataMap.isNotEmpty()) {

                runOnUiThread { channel.invokeMethod("onCardRead", dataMap) }
            }
        } catch (e: Exception) {

            Log.e("USB_TEST", "Error: ${e.message}")
        }
    }

    // ฟังก์ชันช่วยส่งคำสั่งไปยัง USB (PC/SC over USB)

    private fun transmit(
            connection: UsbDeviceConnection,
            endpointIn: UsbEndpoint,
            endpointOut: UsbEndpoint,
            apdu: ByteArray
    ): ByteArray {

        // หุ้มคำสั่ง APDU ด้วย CCID Header (สำหรับเครื่องอ่านบัตรส่วนใหญ่)

        val header =
                byteArrayOf(
                        0x6F.toByte(), // Message Type: PC_to_RDR_XfrBlock
                        (apdu.size and 0xff).toByte(), // Length LSB
                        0x00,
                        0x00,
                        0x00, // Length MSB
                        0x00, // Slot
                        0x00, // Sequence
                        0x00,
                        0x00,
                        0x00 // Reserved
                )

        val command = header + apdu

        connection.bulkTransfer(endpointOut, command, command.size, 2000)

        val response = ByteArray(512)

        val len = connection.bulkTransfer(endpointIn, response, response.size, 2000)

        if (len < 10) return byteArrayOf()

        // ตัด CCID Header ออก (10 ไบต์แรก) และตัด Status SW1, SW2 ออก (2 ไบต์สุดท้าย)

        return response.sliceArray(10 until len - 2)
    }

    private fun sendLog(msg: String) {

        Log.d("USB_TEST", msg)

        runOnUiThread { channel.invokeMethod("onLog", msg) }
    }
}
