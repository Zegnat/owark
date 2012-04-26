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

import java.util.Hashtable;
import java.util.Iterator;
import java.util.Map;

/**
 * Created by IntelliJ IDEA.
 * User: vdv
 * Date: 25 avr. 2012
 * Time: 17:50:01
 * To change this template use File | Settings | File Templates.
 */
public class WarcRecordHeader implements Iterator<WarcField> {


    public static String WARC_TYPE = "WARC-Type";
    public static String CONTENT_TYPE = "Content-Type";
    public static String CONTENT_LENGTH = "Content-Length";

    private WarcRecord warcRecord;
    private String line;
    private Exception e;
    private Map<String,String> headers;
    private boolean endOfHeader = false;


    public WarcRecordHeader(WarcRecord warcRecord) {
        this.warcRecord = warcRecord;
        headers = new Hashtable<String, String>();
    }

    public boolean hasNext() {
        if (endOfHeader) {
            return false;
        }
        if (line == null) {
            try {
                line = warcRecord.readLine();
            } catch (Exception e) {
                this.e  = e;
                return false;
            }
        }
        if (line.equals("")) {
            endOfHeader = true;
            return false;
        }
        return true;
    }

    public WarcField next() {
        if (endOfHeader) {
            return null;
        }
        if (line == null) {
            try {
                line = warcRecord.readLine();
            } catch (Exception e) {
                this.e  = e;
                return null;
            }
        }
        WarcField item = new WarcField(line);
        line = null;
        headers.put(item.getKey(), item.getValue());
        return item;
    }

    public String getType() {
        return headers.get(WARC_TYPE);
    }

    public void remove() {
    }

    public String getContentType() {
        return headers.get(CONTENT_TYPE);
    }

    public int getContentLength() {
        return Integer.parseInt(headers.get(CONTENT_LENGTH));
    }

    public void skipToEnd() {
        while (hasNext()) {
            next();
        }
    }
}
