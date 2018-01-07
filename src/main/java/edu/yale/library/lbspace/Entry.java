package edu.yale.library.lbspace;


import java.util.Date;

public class Entry {

    private int transactionId;

    private Date date;

    private String collectionName;

    private Date dataReady;

    private Date dateStart;

    private Date dateEnd;

    private Date dateFailed;

    private String notes;

    private byte[] export_file;

    public Date getDate() {
        return date;
    }

    public void setDate(Date date) {
        this.date = date;
    }

    public String getCollectionName() {
        return collectionName;
    }

    public void setCollectionName(String collectionName) {
        this.collectionName = collectionName;
    }

    public Date getDataReady() {
        return dataReady;
    }

    public void setDataReady(Date dataReady) {
        this.dataReady = dataReady;
    }

    public Date getDateStart() {
        return dateStart;
    }

    public void setDateStart(Date dateStart) {
        this.dateStart = dateStart;
    }

    public Date getDateEnd() {
        return dateEnd;
    }

    public void setDateEnd(Date dateEnd) {
        this.dateEnd = dateEnd;
    }

    public Date getDateFailed() {
        return dateFailed;
    }

    public void setDateFailed(Date dateFailed) {
        this.dateFailed = dateFailed;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public int getTransactionId() {
        return transactionId;
    }

    public void setTransactionId(int transactionId) {
        this.transactionId = transactionId;
    }

    public byte[] getExport_file() {
        return export_file;
    }

    public void setExport_file(byte[] export_file) {
        this.export_file = export_file;
    }

    public Entry() {
    }
}
