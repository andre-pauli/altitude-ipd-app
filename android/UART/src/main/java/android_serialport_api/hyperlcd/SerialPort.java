package android_serialport_api.hyperlcd;

import android.util.Log;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import android_serialport_api.hyperlcd.SerialPortManager.Type;

class SerialPort {
   private android_serialport_api.SerialPort serialPort;

   private InputStream inputStream;

   private OutputStream outputStream;

   private ReadThread readThread;

   private String port;

   private boolean open;

   private boolean isAscii;

   private int baudRate;

   private int flags;

   private LogInterceptorSerialPort logInterceptor;

   public SerialPort(String port, boolean isAscii, int baudRate, int flags) {
      this.port = port;
      this.isAscii = isAscii;
      this.baudRate = baudRate;
      this.flags = flags;
   }

   public void setLogInterceptor(LogInterceptorSerialPort logInterceptor) {
      this.logInterceptor = logInterceptor;
   }

   private void log(@Type String type, String port, boolean isAscii, CharSequence log) {
      log(type, port, isAscii, (log == null) ? "null" : log.toString());
   }

   private void log(@Type String type, String port, boolean isAscii, String log) {
      if (this.logInterceptor != null)
         this.logInterceptor.log(type, port, isAscii, log);
   }

   public boolean open(BaseReader reader) {
      log("port", this.port, this.isAscii, (new StringBuffer())
              .append("Transmission rate")
                      .append(this.baudRate).append("Bookmark Bit").append(this.flags)
                              .append(" Start serial port"));
      if (this.open) {
         log("port", this.port, this.isAscii, (new StringBuffer()).append("Startup failedport started"));
         return this.open;
      }
      try {
         this.serialPort = new android_serialport_api.SerialPort(new File(this.port), this.baudRate, 0);
         if (this.serialPort == null) {
            log("port", this.port, this.isAscii, (new StringBuffer()).append("Startup failed== null"));
         } else {
            this.inputStream = this.serialPort.getInputStream();
            if (this.inputStream == null)
               throw new Exception("inputStream==null");
            this.outputStream = this.serialPort.getOutputStream();
            if (this.outputStream == null)
               throw new Exception("outputStream==null");
            this.readThread = new ReadThread(this.isAscii, reader);
            this.readThread.start();
            this.open = true;
            log("port", this.port, this.isAscii, (new StringBuffer()).append("Successful startup"));
         }
      } catch (Exception e) {
         e.printStackTrace();
         log("port", this.port, this.isAscii, (new StringBuffer()).append("Startup failed").append(e));
         this.open = false;
      }
      return this.open;
   }

   public boolean isOpen() {
      return this.open;
   }

   public void setReadCode(boolean isAscii) {
      if (this.readThread != null) {
         this.readThread.isAscii = isAscii;
         log("port", this.port, this.readThread.isAscii, (new StringBuffer()).append("Modificar formato de dados").append(isAscii ? "ASCII" : "HexString"));
      }
   }

   public void setReader(BaseReader reader) {
      if (this.readThread != null)
         this.readThread.setReader(reader);
   }

   class ReadThread extends Thread {
      public boolean isRun;

      public boolean isAscii;

      private BaseReader reader;

      public ReadThread(boolean isAscii, BaseReader baseReader) {
         this.reader = baseReader;
         this.isAscii = isAscii;
         if (this.reader != null)
            this.reader.setLogInterceptor(SerialPort.this.logInterceptor);
      }

      public void run() {
         if (SerialPort.this.inputStream == null)
            return;
         this.isRun = true;
         while (this.isRun && !isInterrupted()) {
            try {
               if (SerialPort.this.inputStream.available() > 0) {
                  byte[] buffer = new byte[512];
                  int size = SerialPort.this.inputStream.read(buffer);
                  if (!this.isRun)
                     break;
                  if (this.reader != null &&
                          size > 0)
                     this.reader.onBaseRead(SerialPort.this.port, this.isAscii, buffer, size);
               }
               Thread.sleep(50L);
            } catch (Exception e) {
               e.printStackTrace();
            }
         }
         SerialPort.this.log("port", SerialPort.this.port, this.isAscii, "Thread termination Successful launch of resources");
      }

      public void stopRead() {
         this.isRun = false;
      }

      public void setReader(BaseReader baseReader) {
         this.reader = baseReader;
         if (this.reader != null)
            this.reader.setLogInterceptor(SerialPort.this.logInterceptor);
      }
   }

   public void write(String cmd) {
      write(this.isAscii, cmd);
   }

   public void write(boolean isAscii, String cmd) {
      log("write", this.port, isAscii, (new StringBuffer()).append("Write").append(cmd));
              Log.e("SerialPort", "Serial port  " + isAscii + " " + cmd);
      if (this.outputStream != null) {
         synchronized (this.outputStream) {
            try {
               byte[] bytes;
               if (isAscii) {
                  bytes = cmd.getBytes();
               } else {
                  bytes = TransformUtils.hexStringToBytes(cmd);
               }
               log("write", this.port, isAscii, (new StringBuffer()).append("Successfully Written").append(cmd));
                       Log.e("SerialPort", "Serial port  bytes" + bytes + " " + cmd);
               this.outputStream.write(bytes);
            } catch (Exception e) {
               log("write", this.port, isAscii, (new StringBuffer()).append("Write Failure:").append(e));
            }
         }
      } else {
         log("write", this.port, isAscii, (new StringBuffer()).append("Write Failureis null"));
      }
   }

   public void close() {
      try {
         this.open = false;
         if (this.readThread != null) {
            this.readThread.stopRead();
            log("port", this.port, this.readThread.isAscii, "Serial port successfully closed");
         } else {
            log("port", this.port, false, "Failed to close serial port: serial port is not open");
         }
         if (this.inputStream != null)
            try {
               this.inputStream.close();
            } catch (IOException e) {
               e.printStackTrace();
            }
         if (this.outputStream != null)
            try {
               this.outputStream.close();
            } catch (IOException e) {
               e.printStackTrace();
            }
         if (this.serialPort != null)
            this.serialPort.close();
      } catch (Exception e) {
         e.printStackTrace();
      }
   }
}