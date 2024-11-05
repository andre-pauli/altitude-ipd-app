package android_serialport_api.hyperlcd;

import android_serialport_api.hyperlcd.SerialPortManager.Type;

public interface LogInterceptorSerialPort {
    void log(@Type String paramString1, String paramString2, boolean paramBoolean, String paramString3);
}