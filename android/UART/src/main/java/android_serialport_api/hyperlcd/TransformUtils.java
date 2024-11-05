package android_serialport_api.hyperlcd;

import java.io.ByteArrayOutputStream;
import java.io.UnsupportedEncodingException;
import java.util.Locale;

public class TransformUtils {
    private static String hexString = "0123456789ABCDEF";

    public static String asciiString2HexString(String str) throws UnsupportedEncodingException {
        byte[] bytes = null;
        bytes = str.getBytes("GBK");
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (int i = 0; i < bytes.length; i++) {
            sb.append(hexString.charAt((bytes[i] & 0xF0) >> 4));
            sb.append(hexString.charAt((bytes[i] & 0xF) >> 0));
        }
        return sb.toString();
    }

    public static String hexString2AsciiString(String bytes) throws UnsupportedEncodingException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream(bytes.length() / 2);
        for (int i = 0; i < bytes.length(); i += 2)
            baos.write(hexString.indexOf(bytes.charAt(i)) << 4 | hexString.indexOf(bytes.charAt(i + 1)));
        return new String(baos.toByteArray(), "GBK");
    }

    public static String byte2AsciiString(byte[] buffer, int size) {
        return new String(buffer, 0, size);
    }

    public static byte[] AsciiString2byte(String str) {
        return str.getBytes();
    }

    public static String bytes2HexString(byte[] buffer, int size) {
        StringBuffer sb = new StringBuffer();
        if (buffer == null || size <= 0)
            return null;
        for (int i = 0; i < size; i++) {
            String hex = Integer.toHexString(buffer[i] & 0xFF);
            if (hex.length() < 2)
                sb.append("0");
            sb.append(hex);
        }
        return sb.toString().toLowerCase(Locale.getDefault());
    }

    public static byte[] hexStringToBytes(String hex) {
        byte[] ret = new byte[hex.length() / 2];
        byte[] tmp = hex.getBytes();
        for (int i = 0; i < tmp.length / 2; i++)
            ret[i] = uniteBytes(tmp[i * 2], tmp[i * 2 + 1]);
        return ret;
    }

    private static byte uniteBytes(byte src0, byte src1) {
        byte _b0 = Byte.decode("0x" + new String(new byte[] { src0 })).byteValue();
        _b0 = (byte)(_b0 << 4);
        byte _b1 = Byte.decode("0x" + new String(new byte[] { src1 })).byteValue();
        byte ret = (byte)(_b0 ^ _b1);
        return ret;
    }
}
