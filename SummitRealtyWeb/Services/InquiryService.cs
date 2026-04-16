using Microsoft.EntityFrameworkCore;
using SummitRealtyWeb.Data;
using SummitRealtyWeb.Models;

namespace SummitRealtyWeb.Services;

public class InquiryService
{
    private readonly SummitRealtyContext _context;

    public InquiryService(SummitRealtyContext context)
    {
        _context = context;
    }

    public async Task<Inquiry> SubmitInquiryAsync(Inquiry inquiry)
    {
        inquiry.InquiryDate = DateTime.UtcNow;
        inquiry.Status = InquiryStatus.Pending;
        _context.Inquiries.Add(inquiry);
        await _context.SaveChangesAsync();
        return inquiry;
    }

    public async Task<Appointment> ScheduleShowingAsync(Appointment appointment)
    {
        appointment.Status = AppointmentStatus.Scheduled;
        _context.Appointments.Add(appointment);
        await _context.SaveChangesAsync();
        return appointment;
    }

    public async Task<List<Inquiry>> GetInquiriesForAgentAsync(int agentId)
    {
        return await _context.Inquiries
            .Include(i => i.Property)
            .Where(i => i.AgentId == agentId)
            .OrderByDescending(i => i.InquiryDate)
            .AsNoTracking()
            .ToListAsync();
    }

    public async Task<List<Appointment>> GetAppointmentsForAgentAsync(int agentId)
    {
        return await _context.Appointments
            .Include(a => a.Property)
            .Where(a => a.AgentId == agentId)
            .OrderByDescending(a => a.AppointmentDate)
            .AsNoTracking()
            .ToListAsync();
    }

    public async Task<bool> UpdateInquiryStatusAsync(int inquiryId, InquiryStatus status)
    {
        var inquiry = await _context.Inquiries.FindAsync(inquiryId);
        if (inquiry == null) return false;

        inquiry.Status = status;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> UpdateAppointmentStatusAsync(int appointmentId, AppointmentStatus status)
    {
        var appointment = await _context.Appointments.FindAsync(appointmentId);
        if (appointment == null) return false;

        appointment.Status = status;
        await _context.SaveChangesAsync();
        return true;
    }
}
