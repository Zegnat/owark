/**
 * Copyright (C) 2012 Eric van der Vlist.
 *
 * This program is free software; you can redistribute it and/or modify it under the terms of the
 * GNU Lesser General Public License as published by the Free Software Foundation; either version
 * 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU Lesser General Public License for more details.
 *
 * The full text of the license is available at http://www.gnu.org/copyleft/lesser.html
 */
package org.owark.warc;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.util.Iterator;

/**
 * Read WARC files
 */
public class WarcParser implements Iterator<WarcRecord> {

    public static int BUFFER_SIZE = 1024;
    public static String CRLF = "\r\n";
    public static String CRLFCRLF = CRLF + CRLF;
    public static String MAGIC = "WARC/";
    private InputStream is;
    private byte[] buffer = new byte[BUFFER_SIZE];
    private int index = 0;
    private int limit = -1;
    private String magic;
    private int recordCount;
    

    public WarcParser(InputStream is) {
        this.is = is;
        resetBuffer();
    }

    public String getMagic() throws IOException, WarcException {
        return this.magic;
    }

    private void resetBuffer() {
        index = 0;
    }

    private void readUntil(String stringPattern) throws IOException, WarcException {
        boolean matches = true;
        for (int i=0; i< stringPattern.length() && limit != 0; i++) {
            int c = read();
            buffer[index ++] = (byte) c;
            if (stringPattern.codePointAt(i) != c) {
                matches = false;
                break;
            }
        }
        if (matches) {
            return;
        }
        readUntil(stringPattern);
    }

    protected String readLine() throws IOException, WarcException {
        readUntil(CRLF);
        String line = new String(buffer, 0, index - CRLF.length(), "UTF-8");
        resetBuffer();
        return line;
    }

    public boolean hasNext() {
        limit = -1;
        do {
            try {
                magic = readLine();
            } catch (Exception e) {
                return false;
            }
        } while (! magic.startsWith(MAGIC));
        return true;
    }

    public WarcRecord next() {
        recordCount ++;
        return new WarcRecord(this);
    }

    public void remove() {
    }

    public void setLimit(int limit) {
        this.limit = limit;    
    }

    public boolean isLimitReached() {
        return limit == 0;
    }

    public int read() throws IOException {
        if (limit == 0) {
            return -1;
        }
        if (limit > 0) {
            limit--;
        }
        int c = is.read();
        //System.out.print((char) c);
        return c;
    }

    public int getRecordCount() {
        return recordCount;
    }

    class WarcException extends Exception {}
    class BufferOverflowException extends WarcException {}
    class BadMagicException extends WarcException {}

}
