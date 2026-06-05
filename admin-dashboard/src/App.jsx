import { useState, useEffect, useRef } from 'react';
import axios from 'axios';

const API_BASE = import.meta.env.VITE_API_URL || '/api';

const STATUS_CONFIG = {
  'جديد': { color: 'bg-blue-100 text-blue-700', dot: 'bg-blue-500' },
  'قيد المعالجة': { color: 'bg-orange-100 text-orange-700', dot: 'bg-orange-500' },
  'متأخر': { color: 'bg-red-100 text-red-700', dot: 'bg-red-500' },
  'مصعد': { color: 'bg-purple-100 text-purple-700', dot: 'bg-purple-500' },
  'منتهي': { color: 'bg-green-100 text-green-700', dot: 'bg-green-500' },
};

const CATEGORIES = ['مخالفة بناء', 'نظافة', 'إنارة', 'حفريات', 'تشوه بصري'];

const emptyForm = () => ({
  title: '', category: '', description: '', imageUrl: '',
  address: '', district: '', lat: 24.7136, lng: 46.6753, landmark: '',
});

export default function App() {
  const [tickets, setTickets] = useState([]);
  const [form, setForm] = useState(emptyForm());
  const [submitting, setSubmitting] = useState(false);
  const [selectedTicket, setSelectedTicket] = useState(null);
  const [editingTicket, setEditingTicket] = useState(null);
  const [editForm, setEditForm] = useState(emptyForm());
  const fileInputRef = useRef(null);
  const editFileInputRef = useRef(null);

  const fetchTickets = async () => {
    try {
      const res = await axios.get(`${API_BASE}/tickets`);
      if (res.data && res.data.success && Array.isArray(res.data.data)) {
        setTickets(res.data.data);
      }
    } catch (err) {
      console.warn('تعذر الاتصال بالخادم لجلب البيانات:', err);
    }
  };

  const deleteTicket = async (id) => {
    if (!window.confirm('هل أنت متأكد من حذف هذا البلاغ؟')) return;
    try {
      await axios.delete(`${API_BASE}/tickets/${id}`);
      await fetchTickets();
    } catch (err) {
      console.error('Delete Error:', err);
      alert('فشل حذف البلاغ');
    }
  };

  useEffect(() => {
    fetchTickets();
  }, []);

  const handleInput = (e) => setForm((prev) => ({ ...prev, [e.target.name]: e.target.value }));

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    if (file.size > 2 * 1024 * 1024) {
      alert('⚠️ حجم الصورة يتجاوز 2 ميجابايت');
      if (fileInputRef.current) fileInputRef.current.value = '';
      return;
    }
    const reader = new FileReader();
    reader.onload = () => {
      setForm((prev) => ({ ...prev, imageUrl: reader.result }));
    };
    reader.readAsDataURL(file);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!form.title || !form.category) return alert('الرجاء تعبئة الحقول الأساسية');
    
    setSubmitting(true);
    try {
      const payload = { ...form };
      payload.location = { address: form.address, district: form.district, lat: Number(form.lat), lng: Number(form.lng), landmark: form.landmark };
      delete payload.address; delete payload.district; delete payload.lat; delete payload.lng; delete payload.landmark;
      const res = await axios.post(`${API_BASE}/tickets/add`, payload);
      if (res.data && res.data.success) {
        await fetchTickets();
        setForm(emptyForm());
        alert('✅ تم إضافة البلاغ بنجاح');
      }
    } catch (err) {
      console.error('Submission Error:', err);
      alert('فشل إضافة البلاغ');
    } finally {
      setSubmitting(false);
    }
  };

  const openEditModal = (ticket) => {
    const loc = ticket.location || {};
    setEditForm({
      title: ticket.title, description: ticket.description || '', status: ticket.status,
      imageUrl: ticket.imageUrl || '',
      address: loc.address || '', district: loc.district || '', lat: loc.lat ?? 24.7136,
      lng: loc.lng ?? 46.6753, landmark: loc.landmark || '',
    });
    setEditingTicket(ticket);
    if (editFileInputRef.current) editFileInputRef.current.value = '';
  };

  const handleEditInput = (e) => setEditForm((prev) => ({ ...prev, [e.target.name]: e.target.value }));

  const handleEditFileChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    if (file.size > 2 * 1024 * 1024) {
      alert('⚠️ حجم الصورة يتجاوز 2 ميجابايت');
      if (editFileInputRef.current) editFileInputRef.current.value = '';
      return;
    }
    const reader = new FileReader();
    reader.onload = () => {
      setEditForm((prev) => ({ ...prev, imageUrl: reader.result }));
    };
    reader.readAsDataURL(file);
  };

  const updateTicket = async () => {
    try {
      const payload = { ...editForm };
      payload.location = { address: editForm.address, district: editForm.district, lat: Number(editForm.lat), lng: Number(editForm.lng), landmark: editForm.landmark };
      delete payload.address; delete payload.district; delete payload.lat; delete payload.lng; delete payload.landmark;
      const res = await axios.put(`${API_BASE}/tickets/update/${editingTicket._id}`, payload);
      if (res.data && res.data.success) {
        await fetchTickets();
        setEditingTicket(null);
        alert('✅ تم تحديث البلاغ بنجاح');
      }
    } catch (err) {
      console.error('Update Error:', err);
      alert('فشل تحديث البلاغ');
    }
  };

  const updateStatus = async (id, newStatus) => {
    const prev = [...tickets];
    setTickets((prevList) => prevList.map((t) => (t._id === id ? { ...t, status: newStatus } : t)));
    try {
      await axios.put(`${API_BASE}/tickets/update-status/${id}`, { status: newStatus });
    } catch (err) {
      console.error('Update Status Error:', err);
      setTickets(prev);
    }
  };

  const handleTicketAction = async (id, action, details = '', assignee = '', escalationReason = '', targetEntity = '') => {
    try {
      const payload = { action, details, assignee };
      if (action === 'تصعيد') {
        payload.escalationReason = escalationReason;
        payload.targetEntity = targetEntity;
      }
      const res = await axios.put(`${API_BASE}/tickets/action/${id}`, payload);
      if (res.data && res.data.success) {
        await fetchTickets();
        setSelectedTicket(res.data.data);
      }
    } catch (err) {
      console.error('Action Error:', err);
      alert('فشل تنفيذ الإجراء');
    }
  };

  const kpis = [
    { label: 'إجمالي البلاغات', count: tickets.length, color: 'text-[#1B8354]', bg: 'bg-[#E8F5EE]' },
    { label: 'جديد', count: tickets.filter((t) => t.status === 'جديد').length, color: 'text-blue-600', bg: 'bg-blue-50' },
    { label: 'قيد المعالجة', count: tickets.filter((t) => t.status === 'قيد المعالجة').length, color: 'text-orange-600', bg: 'bg-orange-50' },
    { label: 'متأخر', count: tickets.filter((t) => t.status === 'متأخر').length, color: 'text-red-600', bg: 'bg-red-50' },
    { label: 'منتهي', count: tickets.filter((t) => t.status === 'منتهي').length, color: 'text-green-600', bg: 'bg-green-50' },
  ];

  return (
    <div className="min-h-screen bg-[#F8F9FA]" dir="rtl">
      <Header />
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 space-y-6">
        <KpiRow items={kpis} />
        <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
          <div className="xl:col-span-1">
            <TicketForm
              form={form}
              onChange={handleInput}
              onFileChange={handleFileChange}
              onSubmit={handleSubmit}
              submitting={submitting}
              fileInputRef={fileInputRef}
            />
          </div>
          <div className="xl:col-span-2">
            <TicketTable
              tickets={tickets}
              onStatusChange={updateStatus}
              onDelete={deleteTicket}
              onViewDetails={setSelectedTicket}
              onEdit={openEditModal}
              onRefresh={fetchTickets}
            />
          </div>
        </div>
      </main>
      {selectedTicket && (
        <DetailModal
          ticket={selectedTicket}
          onAction={handleTicketAction}
          onClose={() => setSelectedTicket(null)}
        />
      )}
      {editingTicket && (
        <EditModal
          form={editForm}
          onChange={handleEditInput}
          onFileChange={handleEditFileChange}
          onSave={updateTicket}
          onClose={() => setEditingTicket(null)}
          fileInputRef={editFileInputRef}
        />
      )}
    </div>
  );
}

function Header() {
  return (
    <header className="bg-white shadow-[0_1px_3px_rgba(0,0,0,0.05)]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <img src="/balady-logo.png?v=3" alt="Balady" className="w-11 h-11 rounded-lg" />
            <div className="text-right">
              <h1 className="text-base font-bold text-gray-900">اسم الأمانة باللغة العربية</h1>
              <p className="text-xs text-gray-500">Name of Municipality in English</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-[#1B8354] rounded-full flex items-center justify-center text-white text-sm font-bold">ت</div>
            <span className="text-sm font-semibold text-gray-800">م. تركي بن عبدالرحمن</span>
          </div>
        </div>
      </div>
    </header>
  );
}

function KpiRow({ items }) {
  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4">
      {items.map((kpi) => (
        <div key={kpi.label} className="bg-white rounded-lg shadow-[0_4px_6px_-1px_rgba(0,0,0,0.05)] p-5 text-center">
          <p className="text-sm text-gray-500 font-medium mb-2">{kpi.label}</p>
          <p className={`text-3xl font-bold ${kpi.color}`}>{kpi.count}</p>
        </div>
      ))}
    </div>
  );
}

function TicketForm({ form, onChange, onFileChange, onSubmit, submitting, fileInputRef }) {
  return (
    <div className="bg-white rounded-lg shadow-[0_4px_6px_-1px_rgba(0,0,0,0.05)] p-6">
      <h2 className="text-lg font-bold text-gray-900 mb-5">إضافة بلاغ جديد</h2>
      <form onSubmit={onSubmit} className="space-y-4">
        <div>
          <label className="block text-sm font-semibold text-gray-700 mb-1.5">عنوان البلاغ</label>
          <input type="text" name="title" value={form.title} onChange={onChange} placeholder="أدخل عنوان البلاغ" className="w-full px-4 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#1B8354]/20 focus:border-[#1B8354]" required />
        </div>
        <div>
          <label className="block text-sm font-semibold text-gray-700 mb-1.5">التصنيف</label>
          <select name="category" value={form.category} onChange={onChange} className="w-full px-4 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#1B8354]/20 focus:border-[#1B8354]" required>
            <option value="">اختر التصنيف</option>
            {CATEGORIES.map((cat) => (<option key={cat} value={cat}>{cat}</option>))}
          </select>
        </div>
        <div>
          <label className="block text-sm font-semibold text-gray-700 mb-1.5">صورة البلاغ</label>
          <input type="file" accept="image/*" ref={fileInputRef} onChange={onFileChange} className="w-full text-sm text-gray-500 file:ml-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-[#1B8354]/10 file:text-[#1B8354] hover:file:bg-[#1B8354]/20 cursor-pointer" />
          <p className="text-xs text-gray-400 mt-1.5">الحد الأقصى: 2 ميجابايت</p>
          <div className="flex items-center gap-2 my-3">
            <div className="flex-1 h-px bg-gray-200" />
            <span className="text-xs text-gray-400 font-medium">أو</span>
            <div className="flex-1 h-px bg-gray-200" />
          </div>
          <input type="url" name="imageUrl" value={form.imageUrl} onChange={onChange} placeholder="https://example.com/image.jpg" className="w-full px-4 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#1B8354]/20 focus:border-[#1B8354]" />
          {form.imageUrl && <img src={form.imageUrl} alt="معاينة" className="mt-2 w-full h-32 object-cover rounded-lg border border-gray-200" />}
        </div>
        <div>
          <label className="block text-sm font-semibold text-gray-700 mb-1.5">تفاصيل البلاغ</label>
          <textarea name="description" value={form.description} onChange={onChange} rows={3} placeholder="أدخل تفاصيل البلاغ" className="w-full px-4 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#1B8354]/20 focus:border-[#1B8354] resize-none" required />
        </div>

        <div className="border-t border-gray-100 pt-4">
          <h3 className="text-sm font-bold text-gray-900 mb-3">موقع البلاغ</h3>
          <div className="space-y-3">
            <div>
              <label className="block text-xs font-semibold text-gray-600 mb-1">العنوان</label>
              <input type="text" name="address" value={form.address} onChange={onChange} placeholder例: شارع الملك فهد" className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#1B8354]/20 focus:border-[#1B8354]" />
            </div>
            <div className="flex gap-3">
              <div className="flex-1">
                <label className="block text-xs font-semibold text-gray-600 mb-1">الحي</label>
                <input type="text" name="district" value={form.district} onChange={onChange} placeholder="حي النزهة" className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#1B8354]/20 focus:border-[#1B8354]" />
              </div>
              <div className="flex-1">
                <label className="block text-xs font-semibold text-gray-600 mb-1">معلم قريب</label>
                <input type="text" name="landmark" value={form.landmark} onChange={onChange} placeholder="مدرسة، مسجد" className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#1B8354]/20 focus:border-[#1B8354]" />
              </div>
            </div>
            <div className="flex gap-3">
              <div className="flex-1">
                <label className="block text-xs font-semibold text-gray-600 mb-1">خط العرض (Lat)</label>
                <input type="number" step="any" name="lat" value={form.lat} onChange={onChange} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#1B8354]/20 focus:border-[#1B8354]" />
              </div>
              <div className="flex-1">
                <label className="block text-xs font-semibold text-gray-600 mb-1">خط الطول (Lng)</label>
                <input type="number" step="any" name="lng" value={form.lng} onChange={onChange} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#1B8354]/20 focus:border-[#1B8354]" />
              </div>
            </div>
            <a
              href={`https://www.openstreetmap.org/?mlat=${form.lat}&mlon=${form.lng}#map=15/${form.lat}/${form.lng}`}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1 text-xs text-blue-600 hover:text-blue-800"
            >
              <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M9 6.75V15m6-6v8.25m.503 3.498 4.875-2.437c.381-.19.622-.58.622-1.006V4.82c0-.836-.88-1.38-1.628-1.006l-3.869 1.934c-.317.159-.69.159-1.006 0L9.503 3.252a1.125 1.125 0 0 0-1.006 0L3.622 5.689C3.24 5.88 3 6.27 3 6.695V19.18c0 .836.88 1.38 1.628 1.006l3.869-1.934c.317-.159.69-.159 1.006 0l4.994 2.497c.317.158.69.158 1.006 0Z" />
              </svg>
              عرض على الخريطة
            </a>
          </div>
        </div>

        <button type="submit" disabled={submitting} className="w-full py-3 bg-[#1B8354] text-white font-bold rounded-lg text-sm hover:bg-[#146A43] transition-colors disabled:opacity-50 flex items-center justify-center gap-2">
          {submitting && (
            <svg className="animate-spin h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
            </svg>
          )}
          {submitting ? 'جاري إضافة البلاغ...' : 'إضافة البلاغ'}
        </button>
      </form>
    </div>
  );
}

function EditModal({ form, onChange, onFileChange, onSave, onClose, fileInputRef }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm" onClick={onClose}>
      <div className="bg-white rounded-xl shadow-2xl max-w-lg w-full mx-4 max-h-[90vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
        <div className="p-6 space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-bold text-gray-900">تعديل البلاغ</h3>
            <button onClick={onClose} className="p-1 text-gray-400 hover:text-gray-600 rounded-md">
              <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 18 18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-1.5">عنوان البلاغ</label>
            <input type="text" name="title" value={form.title} disabled className="w-full px-4 py-2.5 border border-gray-200 rounded-lg text-sm bg-gray-50 text-gray-500 cursor-not-allowed" />
          </div>
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-1.5">الحالة</label>
            <select name="status" value={form.status} onChange={onChange} className="w-full px-4 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#1B8354]/20 focus:border-[#1B8354]">
              <option value="جديد">جديد</option>
              <option value="قيد المعالجة">قيد المعالجة</option>
              <option value="متأخر">متأخر</option>
              <option value="مصعد">مصعد</option>
              <option value="منتهي">منتهي</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-1.5">الصورة المرفقة</label>
            <input type="file" accept="image/*" ref={fileInputRef} onChange={onFileChange} className="w-full text-sm text-gray-500 file:ml-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-[#1B8354]/10 file:text-[#1B8354] hover:file:bg-[#1B8354]/20 cursor-pointer" />
            <p className="text-xs text-gray-400 mt-1.5">الحد الأقصى: 2 ميجابايت</p>
            <div className="flex items-center gap-2 my-3">
              <div className="flex-1 h-px bg-gray-200" /><span className="text-xs text-gray-400 font-medium">أو</span><div className="flex-1 h-px bg-gray-200" />
            </div>
            <input type="url" name="imageUrl" value={form.imageUrl} onChange={onChange} placeholder="https://example.com/image.jpg" className="w-full px-4 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#1B8354]/20 focus:border-[#1B8354]" />
            {form.imageUrl && <img src={form.imageUrl} alt="صورة البلاغ" className="mt-2 w-full h-40 object-cover rounded-lg border border-gray-200" />}
          </div>
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-1.5">تفاصيل البلاغ</label>
            <textarea name="description" value={form.description} onChange={onChange} rows={3} className="w-full px-4 py-2.5 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#1B8354]/20 focus:border-[#1B8354] resize-none" />
          </div>

          <div className="border-t border-gray-100 pt-4">
            <h3 className="text-sm font-bold text-gray-900 mb-3">موقع البلاغ</h3>
            <div className="space-y-3">
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1">العنوان</label>
                <input type="text" name="address" value={form.address} onChange={onChange} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#1B8354]/20 focus:border-[#1B8354]" />
              </div>
              <div className="flex gap-3">
                <div className="flex-1">
                  <label className="block text-xs font-semibold text-gray-600 mb-1">الحي</label>
                  <input type="text" name="district" value={form.district} onChange={onChange} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#1B8354]/20 focus:border-[#1B8354]" />
                </div>
                <div className="flex-1">
                  <label className="block text-xs font-semibold text-gray-600 mb-1">معلم قريب</label>
                  <input type="text" name="landmark" value={form.landmark} onChange={onChange} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#1B8354]/20 focus:border-[#1B8354]" />
                </div>
              </div>
              <div className="flex gap-3">
                <div className="flex-1">
                  <label className="block text-xs font-semibold text-gray-600 mb-1">خط العرض (Lat)</label>
                  <input type="number" step="any" name="lat" value={form.lat} onChange={onChange} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#1B8354]/20 focus:border-[#1B8354]" />
                </div>
                <div className="flex-1">
                  <label className="block text-xs font-semibold text-gray-600 mb-1">خط الطول (Lng)</label>
                  <input type="number" step="any" name="lng" value={form.lng} onChange={onChange} className="w-full px-3 py-2 border border-gray-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-[#1B8354]/20 focus:border-[#1B8354]" />
                </div>
              </div>
            </div>
          </div>

          <button onClick={onSave} className="w-full py-3 bg-[#1B8354] text-white font-bold rounded-lg text-sm hover:bg-[#146A43] transition-colors">حفظ التعديلات</button>
        </div>
      </div>
    </div>
  );
}

function TicketTable({ tickets, onStatusChange, onDelete, onViewDetails, onEdit, onRefresh }) {
  return (
    <div className="bg-white rounded-lg shadow-[0_4px_6px_-1px_rgba(0,0,0,0.05)] p-6">
      <div className="flex items-center justify-between mb-5">
        <button onClick={onRefresh} className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold text-[#1B8354] bg-[#E8F5EE] hover:bg-[#1B8354]/20 rounded-lg transition-colors">
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182" />
          </svg>
          تحديث البيانات
        </button>
        <h2 className="text-lg font-bold text-gray-900">جدول مراقبة البلاغات</h2>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-100">
              <th className="text-right py-3 px-3 font-semibold text-gray-600">رقم البلاغ</th>
              <th className="text-right py-3 px-3 font-semibold text-gray-600">العنوان</th>
              <th className="text-right py-3 px-3 font-semibold text-gray-600">التصنيف</th>
              <th className="text-right py-3 px-3 font-semibold text-gray-600">الموقع</th>
              <th className="text-right py-3 px-3 font-semibold text-gray-600">تاريخ الإدراج</th>
              <th className="text-right py-3 px-3 font-semibold text-gray-600">الحالة</th>
              <th className="text-right py-3 px-3 font-semibold text-gray-600">إجراء</th>
            </tr>
          </thead>
          <tbody>
            {tickets.map((ticket) => {
              const cfg = STATUS_CONFIG[ticket.status] || STATUS_CONFIG['جديد'];
              const shortId = ticket._id ? `${ticket._id.substring(0, 6).toUpperCase()}#` : '#000000';
              const loc = ticket.location || {};
              return (
                <tr key={ticket._id} className="border-b border-gray-50 hover:bg-gray-50/50 transition-colors">
                  <td className="py-3 px-3 text-gray-400 font-mono text-xs">{shortId}</td>
                  <td className="py-3 px-3">
                    <div className="flex items-center gap-3">
                      {ticket.imageUrl ? (
                        <img src={ticket.imageUrl} alt="" className="w-14 h-14 rounded-xl object-cover border border-gray-100 shrink-0" />
                      ) : (
                        <div className="w-14 h-14 rounded-xl bg-gray-100 shrink-0 flex items-center justify-center">
                          <svg className="w-6 h-6 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909M3.75 21h16.5A2.25 2.25 0 0 0 22.5 18.75V5.25A2.25 2.25 0 0 0 20.25 3H3.75A2.25 2.25 0 0 0 1.5 5.25v13.5A2.25 2.25 0 0 0 3.75 21Z" />
                          </svg>
                        </div>
                      )}
                      <span className="font-semibold text-gray-900">{ticket.title}</span>
                    </div>
                  </td>
                  <td className="py-3 px-3 text-gray-600">{ticket.category}</td>
                  <td className="py-3 px-3 text-gray-500 text-xs">{loc.district || '-'}</td>
                  <td className="py-3 px-3 text-gray-500">{ticket.createdAt ? new Date(ticket.createdAt).toLocaleDateString('ar-SA') : ''}</td>
                  <td className="py-3 px-3">
                    <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold ${cfg.color}`}>
                      <span className={`w-1.5 h-1.5 rounded-full ${cfg.dot}`} />
                      {ticket.status}
                    </span>
                  </td>
                  <td className="py-3 px-3">
                    <div className="flex items-center gap-2">
                      <button onClick={() => onViewDetails(ticket)} className="text-xs px-3 py-1.5 bg-[#1B8354]/10 text-[#1B8354] hover:bg-[#1B8354]/20 rounded-md transition-colors font-semibold">تفاصيل</button>
                      <button onClick={() => onEdit(ticket)} className="text-xs px-3 py-1.5 bg-blue-50 text-blue-600 hover:bg-blue-100 rounded-md transition-colors font-semibold">تعديل</button>
                      <select value={ticket.status} onChange={(e) => onStatusChange(ticket._id, e.target.value)} className="text-xs px-2 py-1.5 border border-gray-200 rounded-md focus:outline-none focus:ring-2 focus:ring-[#1B8354]/20">
                        <option value="جديد">جديد</option>
                        <option value="قيد المعالجة">قيد المعالجة</option>
                        <option value="متأخر">متأخر</option>
                        <option value="منتهي">منتهي</option>
                      </select>
                      <button onClick={() => onDelete(ticket._id)} className="p-1.5 text-red-400 hover:text-red-600 hover:bg-red-50 rounded-md transition-colors" title="حذف البلاغ">
                        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" />
                        </svg>
                      </button>
                    </div>
                  </td>
                </tr>
              );
            })}
            {tickets.length === 0 && (
              <tr><td colSpan={7} className="py-12 text-center text-gray-400">لا توجد بلاغات حالياً</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function DetailModal({ ticket, onAction, onClose }) {
  const loc = ticket.location || {};
  const progress = ticket.progressLog || [];
  const isNew = ticket.status === 'جديد';
  const isInProgress = ticket.status === 'قيد المعالجة';
  const isCompleted = ticket.status === 'منتهي';
  const [assigneeInput, setAssigneeInput] = useState('');
  const [inquiryInput, setInquiryInput] = useState('');
  const [escalationReason, setEscalationReason] = useState('');
  const [escalationEntity, setEscalationEntity] = useState('');

  const escalateReasons = [
    'خارج الصلاحية', 'خطورة عالية', 'دعم قانوني', 'دعم أمني',
    'موارد إضافية', 'تكرار عالي', 'تعارض مصالح', 'أخرى',
  ];

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm" onClick={onClose}>
      <div className="bg-white rounded-xl shadow-2xl max-w-2xl w-full mx-4 max-h-[90vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
        <div className="relative">
          {ticket.imageUrl ? (
            <img src={ticket.imageUrl} alt={ticket.title} className="w-full h-56 object-cover rounded-t-xl" />
          ) : (
            <div className="w-full h-40 bg-gray-100 rounded-t-xl flex items-center justify-center">
              <svg className="w-16 h-16 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1}>
                <path strokeLinecap="round" strokeLinejoin="round" d="m2.25 15.75 5.159-5.159a2.25 2.25 0 0 1 3.182 0l5.159 5.159m-1.5-1.5 1.409-1.409a2.25 2.25 0 0 1 3.182 0l2.909 2.909M3.75 21h16.5A2.25 2.25 0 0 0 22.5 18.75V5.25A2.25 2.25 0 0 0 20.25 3H3.75A2.25 2.25 0 0 0 1.5 5.25v13.5A2.25 2.25 0 0 0 3.75 21Z" />
              </svg>
            </div>
          )}
          <button onClick={onClose} className="absolute top-3 left-3 w-8 h-8 bg-black/40 hover:bg-black/60 text-white rounded-full flex items-center justify-center transition-colors">
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18 18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div className="p-6 space-y-5">
          {/* عنوان + حالة */}
          <div className="text-right">
            <h3 className="text-xl font-bold text-gray-900">{ticket.title}</h3>
            <p className="text-sm font-mono text-gray-400 mt-1">{ticket.ticketId || ''}</p>
            <div className="flex items-center gap-2 mt-3">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-gray-100 text-gray-600">{ticket.category}</span>
              <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold ${(STATUS_CONFIG[ticket.status] || STATUS_CONFIG['جديد']).color}`}>
                <span className={`w-1.5 h-1.5 rounded-full ${(STATUS_CONFIG[ticket.status] || STATUS_CONFIG['جديد']).dot}`} />
                {ticket.status}
              </span>
            </div>
          </div>

          {/* الوصف */}
          <div className="text-right pt-2 border-t border-gray-100">
            <p className="text-sm font-semibold text-gray-700 mb-1">وصف البلاغ</p>
            <p className="text-sm text-gray-600 leading-relaxed whitespace-pre-wrap">{ticket.description || 'لا توجد تفاصيل إضافية.'}</p>
          </div>

          {/* الموقع */}
          <div className="text-right pt-2 border-t border-gray-100">
            <p className="text-sm font-semibold text-gray-700 mb-2">موقع البلاغ</p>
            <div className="bg-gray-50 rounded-lg overflow-hidden">
              <div className="aspect-video bg-gray-200 flex items-center justify-center">
                <iframe
                  title="map"
                  className="w-full h-full"
                  loading="lazy"
                  src={`https://www.openstreetmap.org/export/embed.html?bbox=${loc.lng - 0.01}%2C${loc.lat - 0.01}%2C${loc.lng + 0.01}%2C${loc.lat + 0.01}&layer=mapnik&marker=${loc.lat}%2C${loc.lng}`}
                />
              </div>
              <div className="p-3 text-xs text-gray-600 space-y-1">
                <p><span className="font-semibold text-gray-700">العنوان:</span> {loc.address || '-'}</p>
                <p><span className="font-semibold text-gray-700">الحي:</span> {loc.district || '-'}</p>
                <p><span className="font-semibold text-gray-700">الإحداثيات:</span> {loc.lat ? `${loc.lat}, ${loc.lng}` : '-'}</p>
                <p><span className="font-semibold text-gray-700">معلم قريب:</span> {loc.landmark || '-'}</p>
              </div>
            </div>
          </div>

          {/* سجل التقدم */}
          <div className="text-right pt-2 border-t border-gray-100">
            <p className="text-sm font-semibold text-gray-700 mb-3">سجل التقدم</p>
            {progress.length === 0 ? (
              <p className="text-xs text-gray-400">لا يوجد سجل تقدم بعد</p>
            ) : (
              <div className="space-y-0">
                {progress.map((entry, i) => (
                  <div key={i} className="flex gap-3">
                    <div className="flex flex-col items-center">
                      <div className={`w-2.5 h-2.5 rounded-full mt-1 ${i === progress.length - 1 ? 'bg-[#1B8354]' : 'bg-gray-300'}`} />
                      {i < progress.length - 1 && <div className="w-0.5 flex-1 bg-gray-200 my-1" />}
                    </div>
                    <div className="flex-1 pb-4">
                      <p className="text-xs font-semibold text-gray-800">{entry.action}</p>
                      <p className="text-xs text-gray-500">{entry.details}</p>
                      {entry.assignee && <p className="text-xs text-gray-400">المسؤول: {entry.assignee}</p>}
                      <p className="text-xs text-gray-400 mt-0.5">{entry.createdAt ? new Date(entry.createdAt).toLocaleString('ar-SA') : ''}</p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* أزرار الإجراءات */}
          {!isCompleted && (
            <div className="pt-2 border-t border-gray-100">
              <p className="text-sm font-semibold text-gray-700 mb-3 text-right">الإجراءات</p>
              <div className="flex flex-wrap gap-2">
                {isInProgress && (
                  <button onClick={() => onAction(ticket._id, 'إنهاء')} className="flex items-center gap-1.5 px-4 py-2 bg-green-600 text-white rounded-lg text-xs font-bold hover:bg-green-700 transition-colors">
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="m4.5 12.75 6 6 9-13.5" />
                    </svg>
                    إنهاء البلاغ
                  </button>
                )}
                {isNew && (
                  <button onClick={() => onAction(ticket._id, 'مباشرة')} className="flex items-center gap-1.5 px-4 py-2 bg-orange-600 text-white rounded-lg text-xs font-bold hover:bg-orange-700 transition-colors">
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 13.5l10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75Z" />
                    </svg>
                    مباشرة البلاغ
                  </button>
                )}
                {(isInProgress || isNew) && (
                  <div className="relative group">
                    <button className="flex items-center gap-1.5 px-4 py-2 bg-purple-600 text-white rounded-lg text-xs font-bold hover:bg-purple-700 transition-colors">
                      <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 6.75h12M8.25 12h12m-12 5.25h12M3.75 6.75h.007v.008H3.75V6.75Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0ZM3.75 12h.007v.008H3.75V12Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Zm-.375 5.25h.007v.008H3.75v-.008Zm.375 0a.375.375 0 1 1-.75 0 .375.375 0 0 1 .75 0Z" />
                      </svg>
                      تصعيد
                    </button>
                    <div className="absolute bottom-full left-0 mb-2 hidden group-hover:block w-72">
                      <div className="bg-white rounded-lg shadow-xl border border-gray-100 p-3 space-y-3">
                        <div>
                          <label className="block text-xs font-semibold text-gray-600 mb-1">سبب التصعيد</label>
                          <select
                            value={escalationReason}
                            onChange={(e) => setEscalationReason(e.target.value)}
                            className="w-full px-3 py-1.5 border border-gray-200 rounded text-xs focus:outline-none focus:ring-1 focus:ring-[#1B8354]"
                          >
                            <option value="">اختر السبب</option>
                            {escalateReasons.map((r) => (
                              <option key={r} value={r}>{r}</option>
                            ))}
                          </select>
                        </div>
                        <div>
                          <label className="block text-xs font-semibold text-gray-600 mb-1">الجهة المصعد لها</label>
                          <input
                            type="text"
                            value={escalationEntity}
                            onChange={(e) => setEscalationEntity(e.target.value)}
                            placeholder="اسم الجهة"
                            className="w-full px-3 py-1.5 border border-gray-200 rounded text-xs focus:outline-none focus:ring-1 focus:ring-[#1B8354]"
                          />
                        </div>
                        <div className="flex gap-2">
                          <button
                            onClick={() => { setEscalationReason(''); setEscalationEntity(''); }}
                            className="flex-1 py-1.5 bg-gray-100 text-gray-600 rounded text-xs font-bold hover:bg-gray-200"
                          >
                            إلغاء
                          </button>
                          <button
                            onClick={() => {
                              if (escalationReason && escalationEntity.trim()) {
                                onAction(ticket._id, 'تصعيد', '', '', escalationReason, escalationEntity.trim());
                                setEscalationReason(''); setEscalationEntity('');
                              }
                            }}
                            className="flex-1 py-1.5 bg-purple-600 text-white rounded text-xs font-bold hover:bg-purple-700"
                          >
                            تصعيد
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                )}
                <div className="relative group">
                  <button className="flex items-center gap-1.5 px-4 py-2 bg-blue-600 text-white rounded-lg text-xs font-bold hover:bg-blue-700 transition-colors">
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M18 7.5v3m0 0v3m0-3h3m-3 0h-3m-2.25-4.125a3.375 3.375 0 1 1-6.75 0 3.375 3.375 0 0 1 6.75 0ZM3 19.235v-.11a6.375 6.375 0 0 1 12.75 0v.109A12.318 12.318 0 0 1 9.374 21c-2.331 0-4.512-.645-6.374-1.766Z" />
                    </svg>
                    تعيين
                  </button>
                  <div className="absolute bottom-full left-0 mb-2 hidden group-hover:block w-64">
                    <div className="bg-white rounded-lg shadow-xl border border-gray-100 p-3">
                      <input
                        type="text"
                        value={assigneeInput}
                        onChange={(e) => setAssigneeInput(e.target.value)}
                        placeholder="اسم المسؤول"
                        className="w-full px-3 py-1.5 border border-gray-200 rounded text-xs mb-2 focus:outline-none focus:ring-1 focus:ring-[#1B8354]"
                      />
                      <button
                        onClick={() => {
                          if (assigneeInput.trim()) {
                            onAction(ticket._id, 'تعيين', '', assigneeInput.trim());
                            setAssigneeInput('');
                          }
                        }}
                        className="w-full py-1.5 bg-[#1B8354] text-white rounded text-xs font-bold hover:bg-[#146A43]"
                      >
                        تأكيد التعيين
                      </button>
                    </div>
                  </div>
                </div>
                <div className="relative group">
                  <button className="flex items-center gap-1.5 px-4 py-2 bg-gray-600 text-white rounded-lg text-xs font-bold hover:bg-gray-700 transition-colors">
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M9.879 7.519c1.171-1.025 3.071-1.025 4.242 0 1.172 1.025 1.172 2.687 0 3.712-.203.179-.43.326-.67.442-.745.361-1.45.999-1.45 1.827v.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9 5.25h.008v.008H12v-.008Z" />
                    </svg>
                    استفسار
                  </button>
                  <div className="absolute bottom-full left-0 mb-2 hidden group-hover:block w-64">
                    <div className="bg-white rounded-lg shadow-xl border border-gray-100 p-3">
                      <textarea
                        value={inquiryInput}
                        onChange={(e) => setInquiryInput(e.target.value)}
                        placeholder="نص الاستفسار"
                        rows={2}
                        className="w-full px-3 py-1.5 border border-gray-200 rounded text-xs mb-2 resize-none focus:outline-none focus:ring-1 focus:ring-[#1B8354]"
                      />
                      <button
                        onClick={() => {
                          if (inquiryInput.trim()) {
                            onAction(ticket._id, 'استفسار', inquiryInput.trim());
                            setInquiryInput('');
                          }
                        }}
                        className="w-full py-1.5 bg-gray-700 text-white rounded text-xs font-bold hover:bg-gray-800"
                      >
                        إرسال الاستفسار
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
