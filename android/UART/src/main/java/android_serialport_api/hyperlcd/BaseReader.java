package android_serialport_api.hyperlcd;

import android_serialport_api.hyperlcd.SerialPortManager.Type;

public abstract class BaseReader {
   private LogInterceptorSerialPort logInterceptor;

   public String port;

   public boolean isAscii;

   void onBaseRead(String port, boolean isAscii, byte[] buffer, int size) {
      String read;
      this.port = port;
      this.isAscii = isAscii;
      if (isAscii) {
         read = new String(buffer, 0, size);
      } else {
         read = TransformUtils.bytes2HexString(buffer, size);
      }
      onParse(port, isAscii, read);
   }

   protected abstract void onParse(String paramString1, boolean paramBoolean, String paramString2);

   public void setLogInterceptor(LogInterceptorSerialPort logInterceptor) {
      this.logInterceptor = logInterceptor;
   }

   protected void log(@Type String type, String port, boolean isAscii, CharSequence log) {
      log(type, port, isAscii, (log == null) ? "null" : log.toString());
   }

   protected void log(@Type String type, String port, boolean isAscii, String log) {
      if (this.logInterceptor != null)
         this.logInterceptor.log(type, port, isAscii, log);
   }
}