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

import java.io.IOException;

/**
 * Created by IntelliJ IDEA.
 * User: vdv
 * Date: 25 avr. 2012
 * Time: 17:29:35
 * To change this template use File | Settings | File Templates.
 */
public class WarcRecord {

    private WarcParser warcParser;
    private WarcRecordHeader header;
    private WarcRecordContent content;

    public WarcRecord(WarcParser warcParser) {
        this.warcParser = warcParser;
    }

    public Object getMagic() throws IOException, WarcParser.WarcException {
        return warcParser.getMagic();
    }

    public WarcRecordHeader getHeader() {
        if (header == null) {
            header = new WarcRecordHeader(this);
        }
        return header;
     }

    public String readLine() throws IOException, WarcParser.WarcException {
        return warcParser.readLine();
    }

    public String getType() {
        return header.getType();
    }

    public String getContentType() {
        return header.getContentType();
    }

    public WarcRecordContent getContent() {
        if (content == null) { 
            warcParser.setLimit(getContentLength());
            content = new WarcRecordContent(this);
        }
        return content;
    }

    public int getContentLength() {
        return header.getContentLength();
    }

    public boolean isLimitReached() {
        return warcParser.isLimitReached();
    }

    public int read() throws IOException {
        return warcParser.read();
    }

    public void skipToEnd() throws IOException {
        getHeader();
        header.skipToEnd();
        getContent();
        content.skip(getContentLength());
    }
}
