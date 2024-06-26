; swift-gen: typedef: cbManagerState CoreBluetooth.CBManagerState
; swift-gen: typedef: cbPeripheral (any CoreBluetoothTestable.PeripheralProtocol)
; swift-gen: typedef: uuid Foundation.UUID
; swift-gen: init: (unwind CBCentralManagerUnknown)

(type cbManagerState
      CBManagerStatePoweredOff
      CBManagerStatePoweredOn
      CBManagerStateResetting
      CBManagerStateUnauthorized
      CBManagerStateUnknown
      CBManagerStateUnsupported)

(type uuid (UUID nat))

(type cbPeripheral (CBPeripheral uuid))

(type evCBCentralManager
      EvCBCentralManagerScanForPeripherals
      EvCBCentralManagerStopScan
      (EvCBCentralManagerDidDiscoverPeripheral cbPeripheral)
      (EvCBCentralManagerDidUpdateState cbManagerState))

(proc CBCentralManagerUnknown ()
      (prefix
        (EvCBCentralManagerDidUpdateState CBManagerStateUnknown)
        (in
          (unwind CBCentralManagerPoweredOnNotScanning)
          (unwind CBCentralManagerPoweredOff)
          (unwind CBCentralManagerResetting)
          (unwind CBCentralManagerUnsupported)
          (unwind CBCentralManagerUnauthorized))))

(proc CBCentralManagerPoweredOnNotScanning ()
      (prefix
        (EvCBCentralManagerDidUpdateState CBManagerStatePoweredOn)
        (ex
          (prefix
            EvCBCentralManagerScanForPeripherals
            (unwind CBCentralManagerPoweredOnScanning 0))
          (in
            (unwind CBCentralManagerPoweredOff)
            (unwind CBCentralManagerResetting)
            (unwind CBCentralManagerUnauthorized)))))

(proc CBCentralManagerPoweredOnScanning ((foundCount nat))
      (ex
          (prefix
            EvCBCentralManagerStopScan
            (unwind CBCentralManagerPoweredOnNotScanning))
          (in
            (prefix
              (EvCBCentralManagerDidDiscoverPeripheral (CBPeripheral (UUID foundCount)))
              (unwind CBCentralManagerPoweredOnScanning (plus nat foundCount 1)))
            (unwind CBCentralManagerPoweredOff)
            (unwind CBCentralManagerResetting)
            (unwind CBCentralManagerUnauthorized))))

(proc CBCentralManagerPoweredOff ()
      (prefix
        (EvCBCentralManagerDidUpdateState CBManagerStatePoweredOff)
        (in
          (unwind CBCentralManagerPoweredOnNotScanning)
          (unwind CBCentralManagerResetting)
          (unwind CBCentralManagerUnauthorized))))

(proc CBCentralManagerUnauthorized ()
      (prefix
        (EvCBCentralManagerDidUpdateState CBManagerStateUnauthorized)
        (in
          (unwind CBCentralManagerPoweredOnNotScanning)
          (unwind CBCentralManagerResetting)
          (unwind CBCentralManagerPoweredOff))))

(proc CBCentralManagerResetting ()
      (prefix
        (EvCBCentralManagerDidUpdateState CBManagerStatePoweredOff)
        (in
          (unwind CBCentralManagerPoweredOnNotScanning)
          (unwind CBCentralManagerPoweredOff)
          (unwind CBCentralManagerUnauthorized))))

(proc CBCentralManagerUnsupported ()
      (prefix
        (EvCBCentralManagerDidUpdateState CBManagerStateUnsupported)
        skip))
