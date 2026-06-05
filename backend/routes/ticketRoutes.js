const express = require('express');
const router = express.Router();
const Ticket = require('../models/Ticket');

// 1. جلب جميع البلاغات (GET) - متوافق مع React وفلاتر
router.get('/', async (req, res) => {
  try {
    const tickets = await Ticket.find().sort({ createdAt: -1 });
    res.json({ success: true, data: tickets });
  } catch (err) {
    res.status(500).json({ success: false, message: 'فشل في جلب البلاغات', error: err.message });
  }
});

// 1b. جلب بلاغ واحد (GET)
router.get('/:id', async (req, res) => {
  try {
    const ticket = await Ticket.findById(req.params.id);
    if (!ticket) {
      return res.status(404).json({ success: false, message: 'البلاغ غير موجود' });
    }
    res.json({ success: true, data: ticket });
  } catch (err) {
    res.status(500).json({ success: false, message: 'فشل في جلب البلاغ', error: err.message });
  }
});

// 2. إضافة بلاغ جديد (POST)
router.post('/add', async (req, res) => {
  try {
    console.log("البيانات القادمة من الداشبورد الحين:", req.body);

    const { title, category, description, imageUrl, location } = req.body;

    const newTicket = new Ticket({ 
      title, 
      category, 
      description: description || '',
      imageUrl: imageUrl || '',
      location: location || {},
      progressLog: [{
        action: 'إنشاء البلاغ',
        details: 'تم إنشاء البلاغ بواسطة مسؤول النظام',
        createdAt: new Date(),
      }],
    });

    const savedTicket = await newTicket.save();
    res.status(201).json({ success: true, data: savedTicket });
  } catch (error) {
    console.error("❌ فشل السيرفر في التحقق من البيانات وحفظها:", error.message);
    res.status(400).json({ success: false, error: error.message });
  }
});

// 3. تحديث حالة البلاغ (PUT) - متطابق 100% مع دالة updateStatus بالداشبورد
router.put('/update-status/:id', async (req, res) => {
  try {
    const updateFields = {};
    if (req.body.status) updateFields.status = req.body.status;
    if (req.body.imageUrl !== undefined) updateFields.imageUrl = req.body.imageUrl;
    const ticket = await Ticket.findByIdAndUpdate(
      req.params.id,
      updateFields,
      { new: true, runValidators: true }
    );
    if (!ticket) {
      return res.status(404).json({ success: false, message: 'البلاغ غير موجود' });
    }
    res.json({ success: true, data: ticket });
  } catch (err) {
    res.status(400).json({ success: false, message: 'فشل في تحديث البلاغ', error: err.message });
  }
});

// 4. تحديث بلاغ كامل (PUT)
router.put('/update/:id', async (req, res) => {
  try {
    const updateFields = {};
    if (req.body.title !== undefined) updateFields.title = req.body.title;
    if (req.body.description !== undefined) updateFields.description = req.body.description;
    if (req.body.imageUrl !== undefined) updateFields.imageUrl = req.body.imageUrl;
    if (req.body.category !== undefined) updateFields.category = req.body.category;
    if (req.body.status !== undefined) updateFields.status = req.body.status;
    if (req.body.location !== undefined) updateFields.location = req.body.location;
    if (req.body.progressLog !== undefined) updateFields.progressLog = req.body.progressLog;

    const ticket = await Ticket.findByIdAndUpdate(
      req.params.id,
      updateFields,
      { new: true, runValidators: true }
    );
    if (!ticket) {
      return res.status(404).json({ success: false, message: 'البلاغ غير موجود' });
    }
    res.json({ success: true, data: ticket });
  } catch (err) {
    res.status(400).json({ success: false, message: 'فشل في تحديث البلاغ', error: err.message });
  }
});

// 5. إضافة إدخال في سجل التقدم (PUT)
router.put('/progress/:id', async (req, res) => {
  try {
    const { action, details, assignee } = req.body;
    const ticket = await Ticket.findById(req.params.id);
    if (!ticket) {
      return res.status(404).json({ success: false, message: 'البلاغ غير موجود' });
    }
    ticket.progressLog.push({ action, details: details || '', assignee: assignee || '', createdAt: new Date() });
    if (req.body.status) ticket.status = req.body.status;
    await ticket.save();
    res.json({ success: true, data: ticket });
  } catch (err) {
    res.status(400).json({ success: false, message: 'فشل في تحديث سجل التقدم', error: err.message });
  }
});

// 6. تنفيذ إجراء على البلاغ (PUT)
router.put('/action/:id', async (req, res) => {
  try {
    const { action, details, assignee, escalationReason, targetEntity } = req.body;
    const ticket = await Ticket.findById(req.params.id);
    if (!ticket) {
      return res.status(404).json({ success: false, message: 'البلاغ غير موجود' });
    }

    const statusMap = {
      'مباشرة': 'قيد المعالجة',
      'تصعيد': 'مصعد',
      'إنهاء': 'منتهي',
      'استفسار': 'قيد المعالجة',
    };

    const newStatus = statusMap[action] || ticket.status;
    ticket.status = newStatus;

    let logDetails = details || '';
    if (action === 'تصعيد') {
      const reason = escalationReason || 'غير محدد';
      const entity = targetEntity || 'غير محدد';
      logDetails = `سبب التصعيد: ${reason}\nالجهة المصعد لها: ${entity}`;
    }

    ticket.progressLog.push({
      action,
      details: logDetails,
      assignee: action === 'تصعيد' ? targetEntity || '' : (assignee || ''),
      createdAt: new Date(),
    });
    if (action === 'تعيين' && assignee) {
      ticket.progressLog.push({
        action: 'توجيه البلاغ',
        details: `تم توجيه البلاغ إلى ${assignee}`,
        assignee,
        createdAt: new Date(),
      });
    }

    await ticket.save();
    res.json({ success: true, data: ticket });
  } catch (err) {
    res.status(400).json({ success: false, message: 'فشل في تنفيذ الإجراء', error: err.message });
  }
});

// 7. حذف بلاغ (DELETE)
router.delete('/:id', async (req, res) => {
  try {
    const ticket = await Ticket.findByIdAndDelete(req.params.id);
    if (!ticket) {
      return res.status(404).json({ success: false, message: 'البلاغ غير موجود' });
    }
    res.json({ success: true, message: 'تم حذف البلاغ بنجاح', data: ticket });
  } catch (err) {
    res.status(400).json({ success: false, message: 'فشل في حذف البلاغ', error: err.message });
  }
});

module.exports = router;