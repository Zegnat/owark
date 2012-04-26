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

import org.junit.Assert;
import org.junit.Test;

import java.io.*;

/**
 * Test cases for WarcParser
 */
public class WarcParserTest {

    private static WarcParser warcParser;

    @Test
    public void testDyomedea() throws IOException, WarcParser.WarcException {

        // WARC

        File file = new File("/home/vdv/projects/owark/archiver/java/test/org/owark/warc/dyomedea.warc");
        WarcParser warcParser = new WarcParser(new FileInputStream(file));
        Assert.assertEquals(true, warcParser.hasNext());

        // RECORD (warcinfo)

        WarcRecord record = warcParser.next();
        Assert.assertEquals("WARC/1.0", warcParser.getMagic());
        Assert.assertNotNull(record);
        Assert.assertEquals("WARC/1.0", record.getMagic());

        // HEADER

        WarcRecordHeader header = record.getHeader();
        Assert.assertNotNull(header);
        Assert.assertNull(header.getType());
        Assert.assertEquals(true, header.hasNext());
        WarcField headerItem = header.next();
        Assert.assertNotNull(headerItem);
        Assert.assertEquals(WarcRecordHeader.WARC_TYPE, headerItem.getKey());
        Assert.assertEquals("warcinfo", headerItem.getValue());
        Assert.assertEquals("warcinfo", header.getType());
        Assert.assertEquals("warcinfo", record.getType());
        Assert.assertEquals(true, header.hasNext());
        headerItem = header.next();
        Assert.assertNotNull(headerItem);
        Assert.assertEquals("WARC-Date", headerItem.getKey());
        Assert.assertEquals("2012-04-23T10:05:24Z", headerItem.getValue());
        headerItem = header.next();
        headerItem = header.next();
        headerItem = header.next();
        headerItem = header.next();
        Assert.assertNotNull(headerItem);
        Assert.assertEquals("Content-Length", headerItem.getKey());
        Assert.assertEquals("369", headerItem.getValue());
        Assert.assertEquals(false, header.hasNext());
        headerItem = header.next();
        Assert.assertNull(headerItem);
        Assert.assertEquals("application/warc-fields", record.getContentType());
        Assert.assertEquals(369, record.getContentLength());

        // Content

        WarcRecordContent content = record.getContent();
        Assert.assertNotNull(content);
        Assert.assertEquals(true, content.hasFields());
        Assert.assertEquals(false, content.isHTTP());
        Assert.assertEquals(false, content.hasStatusLine());
        Assert.assertEquals(false, content.hasRequestLine());
        Assert.assertEquals(true, content.hasNext());
        WarcField field = content.next();
        Assert.assertEquals(false, content.endOfContent());
        Assert.assertNotNull(field);
        Assert.assertEquals("software", field.getKey());
        Assert.assertEquals("Heritrix/3.1.0 http://crawler.archive.org", field.getValue());
        field = content.next();
        field = content.next();
        field = content.next();
        field = content.next();
        field = content.next();
        field = content.next();
        field = content.next();
        field = content.next();
        Assert.assertNotNull(field);
        Assert.assertEquals("http-header-user-agent", field.getKey());
        Assert.assertEquals("Mozilla/5.0 (compatible; heritrix/3.1.0 +http://owark.org)", field.getValue());
        Assert.assertEquals(false, content.hasNext());
        Assert.assertNull(content.getPayloadContentType());
        Assert.assertNull(content.getPayloadContentHeader());
        Assert.assertNull(content.getPayloadEncoding());
        Assert.assertEquals(true, content.endOfContent());

        // Next record (DNS response)

        Assert.assertEquals(true, warcParser.hasNext());
        record = warcParser.next();
        Assert.assertNotNull(record);

        // Header

        header = record.getHeader();
        Assert.assertNotNull(header);
        Assert.assertNull(header.getType());
        Assert.assertEquals(true, header.hasNext());
        headerItem = header.next();
        Assert.assertNotNull(headerItem);
        Assert.assertEquals(WarcRecordHeader.WARC_TYPE, headerItem.getKey());
        Assert.assertEquals("response", headerItem.getValue());

        header.skipToEnd();

        // Content

        content = record.getContent();
        Assert.assertNotNull(content);
        Assert.assertEquals(false, content.hasFields());
        Assert.assertEquals(false, content.isHTTP());
        Assert.assertEquals(false, content.hasStatusLine());
        Assert.assertEquals(false, content.hasRequestLine());
        Assert.assertEquals(false, content.endOfContent());
        BufferedReader reader = new BufferedReader(new InputStreamReader(content, "UTF-8"));
        String line = reader.readLine();
        Assert.assertEquals("20120423100524", line);
        line = reader.readLine();
        Assert.assertEquals("dyomedea.com.\t\t1800\tIN\tA\t95.142.167.137", line);
        line = reader.readLine();
        Assert.assertEquals(true, content.endOfContent());
        Assert.assertEquals("text/dns", content.getPayloadContentType());
        Assert.assertEquals("text/dns", content.getPayloadContentHeader());
        Assert.assertNull(content.getPayloadEncoding());
        Assert.assertNull(line);

        // Next record (HTTP response)

        Assert.assertEquals(true, warcParser.hasNext());
        record = warcParser.next();
        Assert.assertNotNull(record);

        // Header

        header = record.getHeader();
        Assert.assertNotNull(header);
        Assert.assertNull(header.getType());
        Assert.assertEquals(true, header.hasNext());
        headerItem = header.next();
        Assert.assertNotNull(headerItem);
        Assert.assertEquals(WarcRecordHeader.WARC_TYPE, headerItem.getKey());
        Assert.assertEquals("response", headerItem.getValue());

        header.skipToEnd();

        // Content

        content = record.getContent();
        Assert.assertNotNull(content);
        Assert.assertEquals(true, content.hasFields());
        Assert.assertEquals(true, content.isHTTP());
        Assert.assertEquals(false, content.isRequest());
        Assert.assertEquals(true, content.hasStatusLine());
        Assert.assertEquals(false, content.hasRequestLine());
        WarcRecordContent.HttpStatusLine status = content.getStatusLine();
        Assert.assertNotNull(status);
        Assert.assertEquals("HTTP/1.1 404 Introuvable", status.getLine());
        Assert.assertEquals("HTTP/1.1", status.getVersion());
        Assert.assertEquals("404", status.getStatus());
        Assert.assertEquals("Introuvable", status.getReason());
        field = content.next();
        Assert.assertNotNull(field);
        Assert.assertEquals("Date", field.getKey());
        Assert.assertEquals("Mon, 23 Apr 2012 10:05:27 GMT", field.getValue());
        field = content.next();
        field = content.next();
        field = content.next();
        field = content.next();
        field = content.next();
        field = content.next();
        Assert.assertNotNull(field);
        Assert.assertEquals("Connection", field.getKey());
        Assert.assertEquals("close", field.getValue());
        Assert.assertEquals(false, content.hasNext());
        Assert.assertEquals(false, content.endOfContent());
        reader = new BufferedReader(new InputStreamReader(content, "UTF-8"));
        line = reader.readLine();
        Assert.assertEquals("<html><head><title>Apache Tomcat/6.0.24 - Rapport d'erreur</title>", line.substring(0, line.indexOf("<style>")));
        line = reader.readLine();
        Assert.assertNull(line);
        Assert.assertEquals("text/html", content.getPayloadContentType());        
        Assert.assertEquals("text/html;charset=utf-8", content.getPayloadContentHeader());
        Assert.assertEquals("utf-8", content.getPayloadEncoding());
        Assert.assertEquals(true, content.endOfContent());


        // Next record

        Assert.assertEquals(true, warcParser.hasNext());
        record = warcParser.next();
        Assert.assertNotNull(record);

        // Header

        header = record.getHeader();
        Assert.assertNotNull(header);
        Assert.assertNull(header.getType());
        Assert.assertEquals(true, header.hasNext());
        headerItem = header.next();
        Assert.assertNotNull(headerItem);
        Assert.assertEquals(WarcRecordHeader.WARC_TYPE, headerItem.getKey());
        Assert.assertEquals("request", headerItem.getValue());

        header.skipToEnd();

        // Content

        content = record.getContent();
        Assert.assertNotNull(content);
        Assert.assertEquals(true, content.hasFields());
        Assert.assertEquals(true, content.isHTTP());
        Assert.assertEquals(true, content.isRequest());
        Assert.assertEquals(false, content.hasStatusLine());
        Assert.assertEquals(true, content.hasRequestLine());
        WarcRecordContent.HttpRequestLine request = content.getRequestLine();        
        Assert.assertEquals("GET /robots.txt HTTP/1.0", request.getLine());
        Assert.assertEquals("GET", request.getMethod());
        Assert.assertEquals("/robots.txt", request.getUri());
        Assert.assertEquals("HTTP/1.0", request.getVersion());
        field = content.next();
        Assert.assertNotNull(field);
        Assert.assertEquals("User-Agent", field.getKey());
        Assert.assertEquals("Mozilla/5.0 (compatible; heritrix/3.1.0 +http://owark.org)", field.getValue());
        field = content.next();
        field = content.next();
        field = content.next();
        Assert.assertNotNull(field);
        Assert.assertEquals("Host", field.getKey());
        Assert.assertEquals("dyomedea.com", field.getValue());
        Assert.assertEquals(false, content.hasNext());
        Assert.assertEquals(true, content.endOfContent());
        

        // Skip record

        Assert.assertEquals(true, warcParser.hasNext());
        record = warcParser.next();
        Assert.assertNotNull(record);
        record.skipToEnd();
        Assert.assertEquals(true, warcParser.hasNext());
        record = warcParser.next();

        // Header

        header = record.getHeader();
        Assert.assertNotNull(header);
        Assert.assertNull(header.getType());
        Assert.assertEquals(true, header.hasNext());
        headerItem = header.next();
        Assert.assertNotNull(headerItem);
        Assert.assertEquals(WarcRecordHeader.WARC_TYPE, headerItem.getKey());
        Assert.assertEquals("response", headerItem.getValue());
        record.skipToEnd();

        // Go to last record

        while (warcParser.hasNext()) {
            record = warcParser.next();
            Assert.assertNotNull(record);
            record.skipToEnd();
        }

        Assert.assertEquals(69, warcParser.getRecordCount());
        Assert.assertEquals("metadata", record.getType());


    }

    @Test
    public void skipToEnd() throws IOException, WarcParser.WarcException {
        File file = new File("/home/vdv/projects/owark/archiver/java/test/org/owark/warc/dyomedea.warc");
        WarcParser warcParser = new WarcParser(new FileInputStream(file));
        Assert.assertEquals(true, warcParser.hasNext());        
        WarcRecord record = warcParser.next();
        WarcRecordHeader header = record.getHeader();
        while (header.hasNext()) {
            Assert.assertNotNull(header.next());
        }
        WarcRecordContent content = record.getContent();
        while (content.hasNext()) {
            Assert.assertNotNull(content.next());
        }
        record.skipToEnd();


    }

}                                                                                    ;
