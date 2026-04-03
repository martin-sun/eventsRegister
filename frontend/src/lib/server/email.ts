import type { TournamentConfig } from '$lib/types';

interface RegistrationEmailData {
	to: string;
	player1Name: string;
	player2Name: string;
	player1Email: string;
	player2Email: string;
	categoryName: string;
	genderType: string;
	combinedAge: number;
	teamId: string;
	status: string;
	config: TournamentConfig;
	locale: string;
	siteUrl: string;
}

export async function sendRegistrationEmail(
	apiKey: string,
	fromEmail: string,
	data: RegistrationEmailData
): Promise<void> {
	const isZh = data.locale === 'zh';
	const eventName = isZh ? data.config.event_name.zh : data.config.event_name.en;
	const venueName = isZh ? data.config.venue.zh : data.config.venue.en;
	const refCode = data.teamId.replace(/-/g, '').substring(0, 8).toUpperCase();

	const eventDate = new Date(data.config.tournament_date);
	const formattedDate = isZh
		? eventDate.toLocaleDateString('zh-CN', { year: 'numeric', month: 'long', day: 'numeric', weekday: 'short' })
		: eventDate.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' });

	const subject = isZh
		? `报名成功 - ${eventName}（确认号：${refCode}）`
		: `Registration Confirmed - ${eventName} (Ref: ${refCode})`;

	const genderLabel = isZh
		? { mens: '男双', womens: '女双', mixed: '混双' }[data.genderType] ?? data.genderType
		: { mens: "Men's Doubles", womens: "Women's Doubles", mixed: 'Mixed Doubles' }[data.genderType] ?? data.genderType;

	const statusLabel = isZh
		? { confirmed: '已确认', pending: '待确认', waitlist: '候补' }[data.status] ?? data.status
		: { confirmed: 'Confirmed', pending: 'Pending', waitlist: 'Waitlist' }[data.status] ?? data.status;

	const totalFee = data.config.registration_fee * 2;

	const html = buildEmailHtml({
		isZh,
		eventName,
		venueName,
		venueAddress: data.config.venue_address,
		formattedDate,
		refCode,
		player1Name: data.player1Name,
		player2Name: data.player2Name,
		categoryName: data.categoryName,
		genderLabel,
		combinedAge: data.combinedAge,
		statusLabel,
		totalFee,
		etransferEmail: data.config.etransfer_email,
		paymentDeadlineHours: data.config.payment_deadline_hours,
		contactPhone: data.config.contact_phone,
		contactWechat: data.config.contact_wechat,
		siteUrl: data.siteUrl
	});

	// Send to both players
	const recipients = [data.player1Email];
	if (data.player2Email && data.player2Email !== data.player1Email) {
		recipients.push(data.player2Email);
	}

	const response = await fetch('https://api.resend.com/emails', {
		method: 'POST',
		headers: {
			'Content-Type': 'application/json',
			Authorization: `Bearer ${apiKey}`
		},
		body: JSON.stringify({
			from: fromEmail,
			to: recipients,
			subject,
			html
		})
	});

	if (!response.ok) {
		const errorBody = await response.text();
		console.error('[email] Resend API error:', response.status, errorBody);
		throw new Error(`Resend API error: ${response.status} ${errorBody}`);
	}
}

/**
 * Safe wrapper for registration flow — email failure will not block registration.
 * Logs errors but never throws.
 */
export async function sendRegistrationEmailSafe(
	apiKey: string,
	fromEmail: string,
	data: RegistrationEmailData
): Promise<void> {
	try {
		await sendRegistrationEmail(apiKey, fromEmail, data);
	} catch (err) {
		console.error('[email] Failed to send registration email (non-blocking):', err);
	}
}

function buildEmailHtml(d: {
	isZh: boolean;
	eventName: string;
	venueName: string;
	venueAddress: string;
	formattedDate: string;
	refCode: string;
	player1Name: string;
	player2Name: string;
	categoryName: string;
	genderLabel: string;
	combinedAge: number;
	statusLabel: string;
	totalFee: number;
	etransferEmail: string;
	paymentDeadlineHours: number;
	contactPhone: string;
	contactWechat: string;
	siteUrl: string;
}): string {
	const t = d.isZh
		? {
				greeting: '您好',
				successMsg: '您已成功报名以下赛事：',
				refLabel: '确认号',
				detailsTitle: '报名信息',
				player1Label: '报名人',
				player2Label: '搭档',
				categoryLabel: '组别',
				typeLabel: '类型',
				ageLabel: '组合年龄',
				statusLabel: '状态',
				paymentTitle: '付款说明',
				paymentInstr: `请通过 Interac e-Transfer 支付报名费 $${d.totalFee} CAD：`,
				recipientLabel: '收款邮箱',
				memoLabel: '备注（必填）',
				memoValue: d.refCode,
				memoWarning: `请务必在备注中填写确认号 ${d.refCode}，以便识别您的付款。`,
				autoDeposit: '收款方已开启自动存款，无需安全问题。',
				deadline: `请在报名后 ${d.paymentDeadlineHours} 小时内完成付款，逾期未付款的报名可能被取消。`,
				docsTitle: '赛事文件',
				waiverLabel: '免责声明',
				mediaLabel: '媒体发布同意书',
				docsNote: '报名即表示您已同意以上文件的全部条款。',
				contactTitle: '联系方式',
				phoneLabel: '电话',
				wechatLabel: '微信',
				footer: '祝您比赛愉快！',
				orgName: d.eventName + ' 组委会',
				venueLabel: '地点',
				dateLabel: '日期'
			}
		: {
				greeting: 'Hello',
				successMsg: 'You have successfully registered for:',
				refLabel: 'Reference Number',
				detailsTitle: 'Registration Details',
				player1Label: 'Player 1',
				player2Label: 'Player 2',
				categoryLabel: 'Category',
				typeLabel: 'Type',
				ageLabel: 'Combined Age',
				statusLabel: 'Status',
				paymentTitle: 'Payment Instructions',
				paymentInstr: `Please pay the registration fee of $${d.totalFee} CAD via Interac e-Transfer:`,
				recipientLabel: 'Recipient Email',
				memoLabel: 'Memo (Required)',
				memoValue: d.refCode,
				memoWarning: `You MUST include reference number ${d.refCode} in the memo so we can identify your payment.`,
				autoDeposit: 'Auto-deposit is enabled — no security question needed.',
				deadline: `Please complete payment within ${d.paymentDeadlineHours} hours. Unpaid registrations may be cancelled.`,
				docsTitle: 'Event Documents',
				waiverLabel: 'Waiver of Liability',
				mediaLabel: 'Media Release Consent',
				docsNote: 'By registering, you have agreed to the terms of the above documents.',
				contactTitle: 'Contact',
				phoneLabel: 'Phone',
				wechatLabel: 'WeChat',
				footer: 'See you on the court!',
				orgName: d.eventName + ' Organizing Committee',
				venueLabel: 'Venue',
				dateLabel: 'Date'
			};

	return `<!DOCTYPE html>
<html lang="${d.isZh ? 'zh' : 'en'}">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f0fdf4;font-family:'Helvetica Neue',Arial,'Noto Sans SC',sans-serif;">
<div style="max-width:600px;margin:0 auto;padding:24px 16px;">

<!-- Header -->
<div style="background:#064e3b;border-radius:16px 16px 0 0;padding:32px 24px;text-align:center;">
  <h1 style="margin:0;color:#fff;font-size:24px;font-weight:700;">${d.eventName}</h1>
  <p style="margin:8px 0 0;color:rgba(255,255,255,0.8);font-size:14px;">${t.dateLabel}: ${d.formattedDate}</p>
  <p style="margin:4px 0 0;color:rgba(255,255,255,0.8);font-size:14px;">${t.venueLabel}: ${d.venueName}</p>
</div>

<!-- Body -->
<div style="background:#fff;padding:32px 24px;border-radius:0 0 16px 16px;border:1px solid #e2e8f0;border-top:none;">

  <!-- Success banner -->
  <div style="background:#f0fdf4;border:1px solid #bbf7d0;border-radius:12px;padding:16px;text-align:center;margin-bottom:24px;">
    <div style="font-size:36px;margin-bottom:8px;">&#9989;</div>
    <p style="margin:0;color:#064e3b;font-size:16px;font-weight:700;">${t.greeting}, ${d.player1Name}!</p>
    <p style="margin:8px 0 0;color:#047857;font-size:14px;">${t.successMsg}</p>
  </div>

  <!-- Ref Code -->
  <div style="text-align:center;margin-bottom:24px;">
    <span style="color:#64748b;font-size:12px;">${t.refLabel}</span><br>
    <span style="font-family:monospace;font-size:28px;font-weight:700;color:#064e3b;letter-spacing:2px;">${d.refCode}</span>
  </div>

  <!-- Details Table -->
  <h3 style="margin:0 0 12px;font-size:14px;color:#334155;border-bottom:1px solid #e2e8f0;padding-bottom:8px;">${t.detailsTitle}</h3>
  <table style="width:100%;font-size:14px;color:#475569;margin-bottom:24px;" cellpadding="6" cellspacing="0">
    <tr><td style="color:#94a3b8;width:35%;">${t.player1Label}</td><td style="font-weight:600;">${d.player1Name}</td></tr>
    <tr><td style="color:#94a3b8;">${t.player2Label}</td><td style="font-weight:600;">${d.player2Name}</td></tr>
    <tr><td style="color:#94a3b8;">${t.categoryLabel}</td><td style="font-weight:600;">${d.categoryName}</td></tr>
    <tr><td style="color:#94a3b8;">${t.typeLabel}</td><td style="font-weight:600;">${d.genderLabel}</td></tr>
    <tr><td style="color:#94a3b8;">${t.ageLabel}</td><td style="font-weight:600;">${d.combinedAge}</td></tr>
    <tr><td style="color:#94a3b8;">${t.statusLabel}</td><td style="font-weight:600;">${d.statusLabel}</td></tr>
  </table>

  <!-- Payment -->
  <div style="background:#fffbeb;border:1px solid #fde68a;border-radius:12px;padding:16px;margin-bottom:24px;">
    <h3 style="margin:0 0 8px;font-size:14px;color:#92400e;">&#128176; ${t.paymentTitle}</h3>
    <p style="margin:0 0 8px;font-size:13px;color:#78350f;">${t.paymentInstr}</p>
    <table style="width:100%;font-size:13px;color:#78350f;margin-bottom:8px;" cellpadding="4" cellspacing="0">
      <tr><td style="color:#a16207;">${t.recipientLabel}</td><td style="font-weight:700;">${d.etransferEmail}</td></tr>
      <tr><td style="color:#a16207;">${t.memoLabel}</td><td style="font-weight:700;font-family:monospace;">${d.refCode}</td></tr>
    </table>
    <p style="margin:0 0 4px;font-size:12px;color:#b45309;font-weight:600;">&#9888;&#65039; ${t.memoWarning}</p>
    <p style="margin:0 0 2px;font-size:12px;color:#a16207;">${t.autoDeposit}</p>
    <p style="margin:0;font-size:12px;color:#a16207;">${t.deadline}</p>
  </div>

  <!-- Documents -->
  <div style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:12px;padding:16px;margin-bottom:24px;">
    <h3 style="margin:0 0 8px;font-size:14px;color:#334155;">&#128196; ${t.docsTitle}</h3>
    <p style="margin:0 0 4px;font-size:13px;color:#475569;">&#8226; <a href="${d.siteUrl}/waiver" style="color:#047857;text-decoration:underline;">${t.waiverLabel}</a></p>
    <p style="margin:0 0 8px;font-size:13px;color:#475569;">&#8226; <a href="${d.siteUrl}/media-release" style="color:#047857;text-decoration:underline;">${t.mediaLabel}</a></p>
    <p style="margin:0;font-size:12px;color:#94a3b8;">${t.docsNote}</p>
  </div>

  <!-- Contact -->
  <div style="text-align:center;padding-top:16px;border-top:1px solid #e2e8f0;">
    <p style="margin:0 0 4px;font-size:12px;color:#94a3b8;">${t.contactTitle}</p>
    <p style="margin:0 0 2px;font-size:13px;color:#64748b;">${t.phoneLabel}: ${d.contactPhone}</p>
    <p style="margin:0 0 16px;font-size:13px;color:#64748b;">${t.wechatLabel}: ${d.contactWechat}</p>
    <p style="margin:0;font-size:14px;color:#047857;font-weight:600;">&#127992; ${t.footer}</p>
    <p style="margin:8px 0 0;font-size:12px;color:#94a3b8;">${t.orgName}</p>
  </div>

</div>
</div>
</body>
</html>`;
}
