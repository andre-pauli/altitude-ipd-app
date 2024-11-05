package android_serialport_api.hyperlcd;

import android.text.TextUtils;
import android.util.Log;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

public class SerialPortManager {
   private final String TAG = "ADan_SerialPortManager";

   private static SerialPortManager instance;

   private HashMap serialPorts;

   private LogInterceptorSerialPort logInterceptor;

   public static final String port = "port";

   public static final String read = "read";

   public static final String write = "write";

   public static final String append = "append";

   private String currentPort;

   private SerialPortManager() {
      this.serialPorts = new HashMap<>();
      this.currentPort = "";
   }

   public static SerialPortManager getInstances() {
      if (instance == null)
         synchronized (SerialPortManager.class) {
            if (instance == null)
               instance = new SerialPortManager();
         }
      return instance;
   }

   public SerialPortManager setLogInterceptor(LogInterceptorSerialPort logInterceptor) {
      this.logInterceptor = logInterceptor;
      Iterator<Map.Entry> iter = this.serialPorts.entrySet().iterator();
      while (iter.hasNext()) {
         Map.Entry entry = iter.next();
         SerialPort serialPort = (SerialPort)entry.getValue();
         serialPort.setLogInterceptor(logInterceptor);
      }
      return this;
   }

   public boolean startSerialPort(String port, boolean isAscii, BaseReader reader) {
      return startSerialPort(port, isAscii, 9600, 0, reader);
   }

   public boolean startSerialPort(String port, boolean isAscii, int baudRate, int flags, BaseReader reader) {
      SerialPort serial;
      if (TextUtils.equals(this.currentPort, port))
         return false;
      if (this.serialPorts.containsKey(port)) {
         serial = (SerialPort)this.serialPorts.get(port);
      } else {
         serial = new SerialPort(port, isAscii, baudRate, flags);
         this.serialPorts.put(port, serial);
      }
      serial.setLogInterceptor(this.logInterceptor);
      return serial.open(reader);
   }

   public void setReader(String port, BaseReader reader) {
      if (this.serialPorts.containsKey(port)) {
         SerialPort serial = (SerialPort)this.serialPorts.get(port);
         serial.setReader(reader);
      }
   }

   public void setReadCode(String port, boolean isAscii) {
      if (this.serialPorts.containsKey(port)) {
         SerialPort serial = (SerialPort)this.serialPorts.get(port);
         serial.setReadCode(isAscii);
      }
   }

   public int send(String port, String cmd) {
      if (TextUtils.isEmpty(port)) {
         Log.d("SerialPort", "Serial port code is empty");
         return 0;
      }
      String send = "a";
      if (TextUtils.isEmpty(send)) {
         Log.d("SerialPort", "Send Data is empty");
         return 1;
      }
      if (this.serialPorts.containsKey(port)) {
         SerialPort serial = (SerialPort)this.serialPorts.get(port);
         serial.write(cmd);
         return 2;
      }
      Log.d("SerialPort", "Serial port isen't Open");
      return 3;
   }

   public void send(String port, boolean isAscii, String cmd) {
      if (this.serialPorts.containsKey(port)) {
         SerialPort serial = (SerialPort)this.serialPorts.get(port);
         serial.write(isAscii, cmd);
      }
   }

   public void stopSerialPort(String port) {
      if (this.serialPorts.containsKey(port)) {
         SerialPort serial = (SerialPort)this.serialPorts.get(port);
         serial.close();
         this.serialPorts.remove(serial);
         System.gc();
      }
   }

   public void stopSerialPort() {
      String port = this.currentPort;
      if (this.serialPorts.containsKey(port)) {
         SerialPort serial = (SerialPort)this.serialPorts.get(port);
         serial.close();
         this.serialPorts.remove(serial);
         System.gc();
      }
   }

   public boolean isStart(String port) {
      if (this.serialPorts.containsKey(port)) {
         SerialPort serial = (SerialPort)this.serialPorts.get(port);
         return serial.isOpen();
      }
      return false;
   }

   public void destroy() {
      Log.e("ADan_SerialPortManager", "SerialPort destroy");
      try {
         Iterator<Map.Entry> iter = this.serialPorts.entrySet().iterator();
         while (iter.hasNext()) {
            Map.Entry entry = iter.next();
            SerialPort serial = (SerialPort)entry.getValue();
            serial.close();
            this.serialPorts.remove(serial);
         }
         System.gc();
      } catch (Exception e) {
         e.printStackTrace();
      }
   }

   public static @interface Type {}
}