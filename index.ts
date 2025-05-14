import { zValidator } from '@hono/zod-validator'
import { type Context, Hono, type MiddlewareHandler } from 'hono'
import { sign, verify } from 'hono/jwt'
import { logger } from 'hono/logger'
import type { Pool, RowDataPacket } from 'mysql2/promise'
import { createPool } from 'mysql2/promise'
import { z } from 'zod'
enum UserRole {
	USER = 'USER',
	MODERATOR = 'MODERATOR',
	ORGANIZER = 'ORGANIZER',
}
enum EventStatus {
	UPCOMING = 'UPCOMING',
	IN_PROGRESS = 'IN_PROGRESS',
	COMPLETED = 'COMPLETED',
	CANCELLED = 'CANCELLED',
}
enum InvitationStatus {
	PENDING = 'PENDING',
	ACCEPTED = 'ACCEPTED',
	DECLINED = 'DECLINED',
}
enum EmailType {
	INVITATION = 'INVITATION',
	ROLE_CHANGE = 'ROLE_CHANGE',
	EVENT_UPDATE = 'EVENT_UPDATE',
	REMINDER = 'REMINDER',
}
interface EmailData {
	to: string
	subject: string
	message: string
	type: EmailType
	relatedEntityId?: number
}
class Database {
	private static instance: Database
	private pool: Pool
	private constructor() {
		this.pool = createPool({
			host: process.env.DB_HOST || 'localhost',
			user: process.env.DB_USER || 'root',
			password: process.env.DB_PASSWORD || '',
			database: process.env.DB_NAME || 'qr',
			waitForConnections: true,
			connectionLimit: 10,
			queueLimit: 0,
		})
	}
	public static getInstance(): Database {
		if (!Database.instance) {
			Database.instance = new Database()
		}
		return Database.instance
	}
	public getPool(): Pool {
		return this.pool
	}
	public async callProcedure<T extends RowDataPacket>(
		procedure: string,
		params: any[] = [],
	): Promise<{ results: T[]; outParams?: Record<string, any> }> {
		const placeholders = params.map(() => '?').join(',')
		const query = `CALL ${procedure}(${placeholders})`
		try {
			const [response] = await this.pool.query<T[]>(query, params)

			const [results, metadata] = response as [T[], any]
			return { results, outParams: metadata }
		} catch (error: any) {
			if (error.message?.includes('45000')) {
				const customMessage = error.message.match(/SQLSTATE\[45000\]:.+?: (.+)/)
				if (customMessage?.[1]) {
					throw new Error(customMessage[1])
				}
			}
			throw error
		}
	}
	public async executeWithOutParams<T extends RowDataPacket>(
		procedure: string,
		inParams: any[] = [],
		outParamCount = 0,
	): Promise<{ results?: T[]; outParams: Record<string, any> }> {
		let placeholders = ''
		let setStatements = ''
		let selectStatement = ''
		for (let i = 0; i < inParams.length; i++) {
			placeholders += '?, '
		}
		for (let i = 0; i < outParamCount; i++) {
			const paramName = `@out${i}`
			placeholders += `${paramName}, `
			setStatements += `SET ${paramName} = NULL; `
			selectStatement += `${i > 0 ? ', ' : ''}${paramName}`
		}
		placeholders = placeholders.substring(0, placeholders.length - 2)
		const connection = await this.pool.getConnection()
		try {
			await connection.beginTransaction()
			if (outParamCount > 0) {
				await connection.query(setStatements)
			}
			const query = `CALL ${procedure}(${placeholders})`
			const [results] = await connection.query<T[]>(query, inParams)
			const outParams: Record<string, any> = {}
			if (outParamCount > 0 && selectStatement) {
				const [outResults] = await connection.query<RowDataPacket[]>(`SELECT ${selectStatement}`)
				for (let i = 0; i < outParamCount; i++) {
					const paramName = `@out${i}`
					outParams[`out${i}`] = outResults[0][paramName]
				}
			}
			await connection.commit()
			return { results, outParams }
		} catch (error: any) {
			await connection.rollback()
			if (error.message?.includes('45000')) {
				const customMessage = error.message.match(/SQLSTATE\[45000\]:.+?: (.+)/)
				if (customMessage?.[1]) {
					throw new Error(customMessage[1])
				}
			}
			throw error
		} finally {
			connection.release()
		}
	}
}
class SecurityUtils {
	static async hashPassword(password: string): Promise<string> {
		return await Bun.password.hash(password, 'bcrypt')
	}
	static async verifyPassword(password: string, hashedPassword: string): Promise<boolean> {
		return await Bun.password.verify(password, hashedPassword, 'bcrypt')
	}
	static async generateToken(payload: any): Promise<string> {
		const expiresIn = Math.floor(Date.now() / 1000) + 60 * 60 * 24
		return await sign({ ...payload, exp: expiresIn }, process.env.JWT_SECRET || 'qrmark-secret-key')
	}
	static async verifyToken(token: string): Promise<any> {
		return await verify(token, process.env.JWT_SECRET || 'qrmark-secret-key')
	}
	static generateQRToken(data: any): string {
		const payload = {
			...data,
			timestamp: Date.now(),
		}
		const serialized = JSON.stringify(payload)
		const signature = Bun.password.hash(serialized + (process.env.QR_SECRET_KEY || 'qrmark-qr-secret-key'), 'bcrypt')
		return Buffer.from(JSON.stringify({ data: payload, signature })).toString('base64')
	}
	static verifyQRToken(token: string): any {
		try {
			const decoded = JSON.parse(Buffer.from(token, 'base64').toString('utf-8'))
			const { data, signature } = decoded
			const expectedSignature = Bun.password.hash(
				JSON.stringify(data) + (process.env.QR_SECRET_KEY || 'qrmark-qr-secret-key'),
				'bcrypt',
			)
			if (signature !== expectedSignature) {
				throw new Error('Invalid QR token signature')
			}
			return data
		} catch (error) {
			throw new Error('Invalid QR token format')
		}
	}
}
class EmailService {
	private static instance: EmailService
	private constructor() {}
	public static getInstance(): EmailService {
		if (!EmailService.instance) {
			EmailService.instance = new EmailService()
		}
		return EmailService.instance
	}
	public async sendEmail(emailData: EmailData): Promise<boolean> {
		try {
			return true
		} catch (error) {
			return false
		}
	}
	public async sendInvitationEmail(to: string, eventTitle: string, senderName: string, invitationId: number): Promise<boolean> {
		return this.sendEmail({
			to,
			subject: 'New Invitation',
			message: `You have been invited to "${eventTitle}" by ${senderName}`,
			type: EmailType.INVITATION,
			relatedEntityId: invitationId,
		})
	}
	public async sendRoleChangeEmail(to: string, newRole: string, changedByName: string, userId: number): Promise<boolean> {
		return this.sendEmail({
			to,
			subject: 'Role Updated',
			message: `You have been ${newRole === 'MODERATOR' ? 'promoted to Moderator' : 'demoted to User'} by ${changedByName}`,
			type: EmailType.ROLE_CHANGE,
			relatedEntityId: userId,
		})
	}
	public async sendEventUpdateEmail(to: string, eventTitle: string, eventId: number): Promise<boolean> {
		return this.sendEmail({
			to,
			subject: 'Event Updated',
			message: `The event "${eventTitle}" has been updated`,
			type: EmailType.EVENT_UPDATE,
			relatedEntityId: eventId,
		})
	}
	public async sendEventCancellationEmail(to: string, eventTitle: string): Promise<boolean> {
		return this.sendEmail({
			to,
			subject: 'Event Cancelled',
			message: `The event "${eventTitle}" has been cancelled`,
			type: EmailType.EVENT_UPDATE,
		})
	}
	public async sendReminderEmail(to: string, eventTitle: string, startTime: Date, eventId: number): Promise<boolean> {
		return this.sendEmail({
			to,
			subject: 'Event Reminder',
			message: `Reminder: "${eventTitle}" starts on ${startTime.toLocaleDateString()} at ${startTime.toLocaleTimeString()}`,
			type: EmailType.REMINDER,
			relatedEntityId: eventId,
		})
	}
}
const Validators = {
	userSchema: z.object({
		email: z.string().email(),
		fullName: z.string().min(3),
		password: z.string().min(6),
		role: z.enum([UserRole.USER, UserRole.MODERATOR, UserRole.ORGANIZER]).optional(),
	}),
	loginSchema: z.object({
		email: z.string().email(),
		password: z.string(),
	}),
	changePasswordSchema: z.object({
		currentPassword: z.string(),
		newPassword: z.string().min(6),
	}),
	locationSchema: z.object({
		name: z.string().min(3),
		address: z.string().optional(),
		mapsUrl: z.string().url().optional(),
	}),
	updateLocationSchema: z.object({
		name: z.string().min(3).optional(),
		address: z.string().optional(),
		mapsUrl: z.string().url().optional(),
	}),
	eventSchema: z.object({
		title: z.string().min(3),
		description: z.string(),
		locationId: z.number().int().positive(),
		startTime: z.string().datetime(),
		endTime: z.string().datetime(),
		isPublished: z.boolean().optional(),
		capacity: z.number().int().positive().optional(),
		requiresCheckout: z.boolean().optional(),
		checkoutToleranceMinutes: z.number().int().min(0).optional(),
		isRecurring: z.boolean().optional(),
		recurrencePattern: z.string().optional(),
	}),
	updateEventSchema: z.object({
		title: z.string().min(3).optional(),
		description: z.string().optional(),
		locationId: z.number().int().positive().optional(),
		startTime: z.string().datetime().optional(),
		endTime: z.string().datetime().optional(),
		isPublished: z.boolean().optional(),
		capacity: z.number().int().positive().optional(),
		requiresCheckout: z.boolean().optional(),
		checkoutToleranceMinutes: z.number().int().min(0).optional(),
	}),
	distributionListSchema: z.object({
		name: z.string().min(3),
		description: z.string().optional(),
	}),
	updateDistributionListSchema: z.object({
		name: z.string().min(3).optional(),
		description: z.string().optional(),
	}),
	invitationSchema: z.object({
		eventId: z.number().int().positive(),
		userId: z.number().int().positive(),
	}),
	bulkInvitationSchema: z.object({
		eventId: z.number().int().positive(),
		userIds: z.string(),
	}),
	listInvitationSchema: z.object({
		eventId: z.number().int().positive(),
		listId: z.number().int().positive(),
	}),
	invitationResponseSchema: z.object({
		status: z.enum([InvitationStatus.ACCEPTED, InvitationStatus.DECLINED]),
	}),
	qrValidationSchema: z.object({
		token: z.string(),
	}),
}
class AuthService {
	private db: Database
	private emailService: EmailService
	constructor() {
		this.db = Database.getInstance()
		this.emailService = EmailService.getInstance()
	}
	async register(
		email: string,
		fullName: string,
		password: string,
		role: UserRole = UserRole.USER,
	): Promise<{ id: number; token: string }> {
		const passwordHash = await SecurityUtils.hashPassword(password)
		const { outParams } = await this.db.executeWithOutParams('sp_CreateUser', [email, fullName, passwordHash, role], 1)
		const userId = outParams.out0
		if (!userId) {
			throw new Error('Failed to create user')
		}
		const token = await SecurityUtils.generateToken({
			userId,
			email,
			role,
			fullName,
		})
		return { id: userId, token }
	}
	async login(email: string, password: string): Promise<{ id: number; token: string; role: UserRole }> {
		const { results: users } = await this.db.callProcedure('sp_GetUserByEmail', [email])
		if (users.length === 0) throw new Error('Credenciales inválidas')
		const user = users[0] as any
		const isPasswordValid = await SecurityUtils.verifyPassword(password, user.passwordHash)
		if (!isPasswordValid) throw new Error('Credenciales inválidas')
		const token = await SecurityUtils.generateToken({
			userId: user.id,
			email: user.email,
			role: user.role,
			fullName: user.fullName,
		})
		return {
			id: user.id,
			token,
			role: user.role as UserRole,
		}
	}
	async changePassword(userId: number, currentPassword: string, newPassword: string): Promise<boolean> {
		const { results: users } = await this.db.callProcedure('sp_GetUserById', [userId])
		if (users.length === 0) {
			throw new Error('User not found')
		}
		const user = users[0] as any
		const { results: userWithPassword } = await this.db.callProcedure('sp_GetUserByEmail', [user.email])
		if (userWithPassword.length === 0) {
			throw new Error('User not found')
		}
		const isPasswordValid = await SecurityUtils.verifyPassword(currentPassword, (userWithPassword[0] as any).passwordHash)
		if (!isPasswordValid) {
			throw new Error('Current password is incorrect')
		}
		const newPasswordHash = await SecurityUtils.hashPassword(newPassword)
		const { outParams } = await this.db.executeWithOutParams('sp_ChangeUserPassword', [userId, newPasswordHash], 1)
		return outParams.out0 === 1
	}
	async verifyToken(token: string): Promise<any> {
		try {
			const decoded = await SecurityUtils.verifyToken(token)
			if (!decoded || !decoded.userId) {
				throw new Error('Invalid token')
			}
			return decoded
		} catch (error) {
			throw new Error('Authentication failed')
		}
	}
}
class UserService {
	private db: Database
	private emailService: EmailService
	constructor() {
		this.db = Database.getInstance()
		this.emailService = EmailService.getInstance()
	}
	async getUserById(id: number): Promise<any> {
		const { results } = await this.db.callProcedure('sp_GetUserById', [id])
		if (results.length === 0) {
			return null
		}
		return results[0]
	}
	async getUserEmail(id: number): Promise<string | null> {
		const user = await this.getUserById(id)
		return user ? user.email : null
	}
	async updateUser(id: number, data: { fullName?: string }): Promise<boolean> {
		const { outParams } = await this.db.executeWithOutParams('sp_UpdateUser', [id, data.fullName, null], 1)
		return outParams.out0 === 1
	}
	async getAllUsers(): Promise<any[]> {
		const { results } = await this.db.callProcedure('sp_GetAllUsers')
		return results as any[]
	}
	async getAllModerators(): Promise<any[]> {
		const { results } = await this.db.callProcedure('sp_GetAllModerators')
		return results as any[]
	}

	async promoteToModerator(userId: number, promotedByUserId: number): Promise<boolean> {
		const { outParams } = await this.db.executeWithOutParams('sp_PromoteUserToModerator', [userId, promotedByUserId], 1)
		if (outParams.out0 === 1) {
			const userEmail = await this.getUserEmail(userId)
			const promotedBy = await this.getUserById(promotedByUserId)
			if (userEmail && promotedBy) {
				await this.emailService.sendRoleChangeEmail(userEmail, 'MODERATOR', promotedBy.fullName, userId)
			}
			return true
		}
		return false
	}
	async demoteToUser(userId: number, demotedByUserId: number): Promise<boolean> {
		const { outParams } = await this.db.executeWithOutParams('sp_DemoteModeratorToUser', [userId, demotedByUserId], 1)
		if (outParams.out0 === 1) {
			const userEmail = await this.getUserEmail(userId)
			const demotedBy = await this.getUserById(demotedByUserId)
			if (userEmail && demotedBy) {
				await this.emailService.sendRoleChangeEmail(userEmail, 'USER', demotedBy.fullName, userId)
			}
			return true
		}
		return false
	}
}
class LocationService {
	private db: Database
	constructor() {
		this.db = Database.getInstance()
	}
	async getLocationById(id: number): Promise<any> {
		const { results } = await this.db.callProcedure('sp_GetLocationById', [id])
		if (results.length === 0) {
			return null
		}
		return results[0]
	}
	async createLocation(data: { name: string; address?: string; mapsUrl?: string }): Promise<number> {
		const { outParams } = await this.db.executeWithOutParams(
			'sp_CreateLocation',
			[data.name, data.address || null, data.mapsUrl || null],
			1,
		)
		return outParams.out0
	}
	async updateLocation(id: number, data: { name?: string; address?: string; mapsUrl?: string }): Promise<boolean> {
		const { outParams } = await this.db.executeWithOutParams(
			'sp_UpdateLocation',
			[id, data.name || null, data.address || null, data.mapsUrl || null],
			1,
		)
		return outParams.out0 === 1
	}
	async deleteLocation(id: number): Promise<boolean> {
		const { outParams } = await this.db.executeWithOutParams('sp_DeleteLocation', [id], 1)
		return outParams.out0 === 1
	}
	async getAllLocations(): Promise<any[]> {
		const { results } = await this.db.callProcedure('sp_GetAllLocations')
		return results as any[]
	}
}
class EventService {
	private db: Database
	private emailService: EmailService
	private userService: UserService
	constructor() {
		this.db = Database.getInstance()
		this.emailService = EmailService.getInstance()
		this.userService = new UserService()
	}
	async getEventById(id: number): Promise<any> {
		const { results } = await this.db.callProcedure('sp_GetEventById', [id])
		if (results.length === 0) {
			return null
		}
		return results[0]
	}
	async createEvent(data: {
		title: string
		description: string
		locationId: number
		startTime: Date
		endTime: Date
		isPublished?: boolean
		capacity?: number
		requiresCheckout?: boolean
		checkoutToleranceMinutes?: number
		organizerId: number
		isRecurring?: boolean
		recurrencePattern?: string
	}): Promise<number> {
		const { outParams } = await this.db.executeWithOutParams(
			'sp_CreateEvent',
			[
				data.title,
				data.description,
				data.locationId,
				data.startTime,
				data.endTime,
				data.isPublished === undefined ? null : data.isPublished,
				data.capacity || null,
				data.requiresCheckout === undefined ? null : data.requiresCheckout,
				data.checkoutToleranceMinutes || null,
				data.organizerId,
				data.isRecurring === undefined ? null : data.isRecurring,
				data.recurrencePattern || null,
			],
			1,
		)
		return outParams.out0
	}
	async updateEvent(
		id: number,
		data: {
			title?: string
			description?: string
			locationId?: number
			startTime?: Date
			endTime?: Date
			isPublished?: boolean
			capacity?: number
			requiresCheckout?: boolean
			checkoutToleranceMinutes?: number
		},
		organizerId: number,
	): Promise<boolean> {
		const { outParams } = await this.db.executeWithOutParams(
			'sp_UpdateEvent',
			[
				id,
				data.title || null,
				data.description || null,
				data.locationId || null,
				data.startTime || null,
				data.endTime || null,
				data.isPublished === undefined ? null : data.isPublished,
				data.capacity || null,
				data.requiresCheckout === undefined ? null : data.requiresCheckout,
				data.checkoutToleranceMinutes || null,
				organizerId,
			],
			1,
		)
		if (outParams.out0 === 1) {
			const event = await this.getEventById(id)
			if (event?.isPublished) {
				await this.sendEventUpdateEmails(id, event.title)
			}
		}
		return outParams.out0 === 1
	}
	private async sendEventUpdateEmails(eventId: number, eventTitle: string): Promise<void> {
		const attendances = await this.getAttendanceEmails(eventId)
		const acceptedInvitations = await this.getAcceptedInvitationEmails(eventId)
		const allEmails = new Set([...attendances, ...acceptedInvitations])
		const promises = Array.from(allEmails).map(email => this.emailService.sendEventUpdateEmail(email, eventTitle, eventId))
		await Promise.all(promises)
	}
	private async getAttendanceEmails(eventId: number): Promise<string[]> {
		try {
			const { results } = await this.db.callProcedure('sp_GetAttendancesByEvent', [eventId])
			return results.map((attendance: any) => attendance.email).filter(Boolean)
		} catch (error) {
			return []
		}
	}
	private async getAcceptedInvitationEmails(eventId: number): Promise<string[]> {
		try {
			const { results } = await this.db.callProcedure('sp_GetInvitationsByEvent', [eventId])
			return results
				.filter((invitation: any) => invitation.status === 'ACCEPTED')
				.map((invitation: any) => invitation.email)
				.filter(Boolean)
		} catch (error) {
			return []
		}
	}
	async deleteEvent(id: number, organizerId: number): Promise<boolean> {
		const event = await this.getEventById(id)
		if (!event) {
			throw new Error('Event not found')
		}
		const attendanceEmails = await this.getAttendanceEmails(id)
		const acceptedInvitationEmails = await this.getAcceptedInvitationEmails(id)
		const allEmails = [...new Set([...attendanceEmails, ...acceptedInvitationEmails])]
		const { outParams } = await this.db.executeWithOutParams('sp_DeleteEvent', [id, organizerId], 1)
		if (outParams.out0 === 1 && allEmails.length > 0) {
			const emailPromises = allEmails.map(email => this.emailService.sendEventCancellationEmail(email, event.title))
			await Promise.all(emailPromises)
		}
		return outParams.out0 === 1
	}
	async getEventsByOrganizer(organizerId: number, status: string): Promise<any[]> {
		const { results } = await this.db.callProcedure('sp_GetEventsByOrganizer', [organizerId, status])
		return results as any[]
	}
	async getUpcomingEvents(): Promise<any[]> {
		const { results } = await this.db.callProcedure('sp_GetUpcomingEvents')
		return results as any[]
	}
	async getInProgressEvents(): Promise<any[]> {
		const { results } = await this.db.callProcedure('sp_GetInProgressEvents')
		return results as any[]
	}
	async getUserEvents(userId: number): Promise<any[]> {
		const { results } = await this.db.callProcedure('sp_GetEventsByUser', [userId])
		return results as any[]
	}
	async publishEvent(id: number, organizerId: number): Promise<boolean> {
		const { outParams } = await this.db.executeWithOutParams('sp_PublishEvent', [id, organizerId], 1)
		return outParams.out0 === 1
	}
	async cancelEvent(id: number, organizerId: number): Promise<boolean> {
		const event = await this.getEventById(id)
		if (!event) {
			throw new Error('Event not found')
		}
		const attendanceEmails = await this.getAttendanceEmails(id)
		const acceptedInvitationEmails = await this.getAcceptedInvitationEmails(id)
		const allEmails = [...new Set([...attendanceEmails, ...acceptedInvitationEmails])]
		const { outParams } = await this.db.executeWithOutParams('sp_CancelEvent', [id, organizerId], 1)
		if (outParams.out0 === 1 && allEmails.length > 0) {
			const emailPromises = allEmails.map(email => this.emailService.sendEventCancellationEmail(email, event.title))
			await Promise.all(emailPromises)
		}
		return outParams.out0 === 1
	}
}
class AttendanceService {
	private db: Database
	constructor() {
		this.db = Database.getInstance()
	}
	async getAttendancesByEvent(eventId: number): Promise<any[]> {
		const { results } = await this.db.callProcedure('sp_GetAttendancesByEvent', [eventId])
		return results as any[]
	}
	async getAttendancesByUser(userId: number): Promise<any[]> {
		const { results } = await this.db.callProcedure('sp_GetAttendancesByUser', [userId])
		return results as any[]
	}
	async getAttendanceStats(eventId: number): Promise<any> {
		const { results } = await this.db.callProcedure('sp_GetAttendanceStats', [eventId])
		return results[0]
	}
	async recordCheckin(eventId: number, userId: number, scannedByUserId: number): Promise<boolean> {
		const { outParams } = await this.db.executeWithOutParams('sp_RecordCheckin', [eventId, userId, scannedByUserId], 1)
		return outParams.out0 === 1
	}
	async recordCheckout(eventId: number, userId: number, scannedByUserId: number): Promise<boolean> {
		const { outParams } = await this.db.executeWithOutParams('sp_RecordCheckout', [eventId, userId, scannedByUserId], 1)
		return outParams.out0 === 1
	}
	async canGenerateCheckinQR(eventId: number, userId: number): Promise<{ canGenerate: boolean; message: string }> {
		const { outParams } = await this.db.executeWithOutParams('sp_CanGenerateCheckinQR', [eventId, userId], 2)
		return {
			canGenerate: outParams.out0 === 1,
			message: outParams.out1,
		}
	}
	// async canGenerateCheckoutQR(eventId: number, userId: number): Promise<{ canGenerate: boolean; message: string }> {
	// 	const { outParams } = await this.db.executeWithOutParams('sp_CanGenerateCheckoutQR', [eventId, userId], 2)
	// 	return {
	// 		canGenerate: outParams.out0 === 1,
	// 		message: outParams.out1,
	// 	}
	// }
	async generateCheckinQR(eventId: number, userId: number): Promise<string> {
		// const canGenerate = await this.canGenerateCheckinQR(eventId, userId)
		// if (!canGenerate.canGenerate) {
		// 	throw new Error(canGenerate.message)
		// }
		const { results: eventResults } = await this.db.callProcedure('sp_GetEventById', [eventId])
		const { results: userResults } = await this.db.callProcedure('sp_GetUserById', [userId])
		if (eventResults.length === 0 || userResults.length === 0) {
			throw new Error('Event or user not found')
		}
		const event = eventResults[0] as any
		const user = userResults[0] as any
		return SecurityUtils.generateQRToken({
			eventId,
			userId,
			type: 'checkin',
			eventTitle: event.title,
			userName: user.fullName,
		})
	}
	async generateCheckoutQR(eventId: number, userId: number): Promise<string> {
		// const canGenerate = await this.canGenerateCheckoutQR(eventId, userId)
		// if (!canGenerate.canGenerate) {
		// throw new Error(canGenerate.message)
		// }
		const { results: eventResults } = await this.db.callProcedure('sp_GetEventById', [eventId])
		const { results: userResults } = await this.db.callProcedure('sp_GetUserById', [userId])
		if (eventResults.length === 0 || userResults.length === 0) {
			throw new Error('Event or user not found')
		}
		const event = eventResults[0] as any
		const user = userResults[0] as any
		return SecurityUtils.generateQRToken({
			eventId,
			userId,
			type: 'checkout',
			eventTitle: event.title,
			userName: user.fullName,
		})
	}
	async processQRToken(token: string, scannedByUserId: number): Promise<{ success: boolean; message: string }> {
		try {
			const tokenData = SecurityUtils.verifyQRToken(token)
			if (!tokenData || !tokenData.eventId || !tokenData.userId || !tokenData.type) {
				return { success: false, message: 'Invalid QR token' }
			}
			const { eventId, userId, type } = tokenData
			if (type === 'checkin') {
				const success = await this.recordCheckin(eventId, userId, scannedByUserId)
				return { success, message: success ? 'Check-in successful' : 'Check-in failed' }
			}
			if (type === 'checkout') {
				const success = await this.recordCheckout(eventId, userId, scannedByUserId)
				return { success, message: success ? 'Check-out successful' : 'Check-out failed' }
			}
			return { success: false, message: 'Invalid QR token type' }
		} catch (error: any) {
			return { success: false, message: error.message }
		}
	}
}
class DistributionListService {
	private db: Database
	constructor() {
		this.db = Database.getInstance()
	}
	async getListById(id: number): Promise<any> {
		const { results } = await this.db.callProcedure('sp_GetDistributionListById', [id])
		if (results.length === 0) {
			return null
		}
		return results[0]
	}
	async createList(name: string, description: string | undefined, organizerId: number): Promise<number> {
		const { outParams } = await this.db.executeWithOutParams(
			'sp_CreateDistributionList',
			[name, description || null, organizerId],
			1,
		)
		return outParams.out0
	}
	async updateList(id: number, data: { name?: string; description?: string }, organizerId: number): Promise<boolean> {
		const { outParams } = await this.db.executeWithOutParams(
			'sp_UpdateDistributionList',
			[id, data.name || null, data.description || null, organizerId],
			1,
		)
		return outParams.out0 === 1
	}
	async deleteList(id: number, organizerId: number): Promise<boolean> {
		const { outParams } = await this.db.executeWithOutParams('sp_DeleteDistributionList', [id, organizerId], 1)
		return outParams.out0 === 1
	}
	async getListsByOrganizer(organizerId: number): Promise<any[]> {
		const { results } = await this.db.callProcedure('sp_GetDistributionListsByOrganizer', [organizerId])
		return results as any[]
	}
	async addMemberToList(listId: number, userId: number, organizerId: number): Promise<boolean> {
		const { outParams } = await this.db.executeWithOutParams('sp_AddMemberToDistributionList', [listId, userId, organizerId], 1)
		return outParams.out0 === 1
	}
	async addMultipleMembersToList(listId: number, userIds: number[], organizerId: number): Promise<boolean> {
		const { outParams } = await this.db.executeWithOutParams(
			'sp_AddMultipleMembersToDistributionList',
			[listId, userIds.join(','), organizerId],
			1,
		)
		return outParams.out0 === 1
	}

	async removeMemberFromList(listId: number, userId: number, organizerId: number): Promise<boolean> {
		const { outParams } = await this.db.executeWithOutParams(
			'sp_RemoveMemberFromDistributionList',
			[listId, userId, organizerId],
			1,
		)
		return outParams.out0 === 1
	}
	async getListMembers(listId: number): Promise<any[]> {
		const { results } = await this.db.callProcedure('sp_GetDistributionListMembers', [listId])
		return results as any[]
	}
}
class InvitationService {
	private db: Database
	private emailService: EmailService
	private userService: UserService
	constructor() {
		this.db = Database.getInstance()
		this.emailService = EmailService.getInstance()
		this.userService = new UserService()
	}
	async getInvitationById(id: number): Promise<any> {
		const { results } = await this.db.callProcedure('sp_GetInvitationById', [id])
		if (results.length === 0) {
			return null
		}
		return results[0]
	}
	async createInvitation(eventId: number, userId: number, senderId: number): Promise<number> {
		const { outParams } = await this.db.executeWithOutParams('sp_CreateInvitation', [eventId, userId, senderId], 1)
		const invitationId = outParams.out0
		if (invitationId) {
			const event = await this.db.callProcedure('sp_GetEventById', [eventId])
			const sender = await this.userService.getUserById(senderId)
			const user = await this.userService.getUserById(userId)
			if (event.results.length > 0 && sender && user && user.email) {
				await this.emailService.sendInvitationEmail(user.email, event.results[0].title, sender.fullName, invitationId)
			}
		}
		return invitationId
	}
	async bulkCreateInvitations(eventId: number, userIds: string, senderId: number): Promise<number> {
		const { outParams } = await this.db.executeWithOutParams('sp_BulkCreateInvitations', [eventId, userIds, senderId], 1)
		const createdCount = outParams.out0
		if (createdCount > 0) {
			const event = await this.db.callProcedure('sp_GetEventById', [eventId])
			const sender = await this.userService.getUserById(senderId)
			if (event.results.length > 0 && sender) {
				const eventTitle = event.results[0].title
				const senderName = sender.fullName
				const { results: invitations } = await this.db.callProcedure('sp_GetInvitationsByEvent', [eventId])
				const userIdArray = userIds.split(',').map(id => Number(id.trim()))
				const newInvitations = invitations.filter((inv: any) => userIdArray.includes(inv.userId) && inv.status === 'PENDING')
				for (const invitation of newInvitations) {
					const user = await this.userService.getUserById(invitation.userId)
					if (user?.email) {
						await this.emailService.sendInvitationEmail(user.email, eventTitle, senderName, invitation.id)
					}
				}
			}
		}
		return createdCount
	}
	async inviteList(eventId: number, listId: number, senderId: number): Promise<number> {
		const { outParams } = await this.db.executeWithOutParams('sp_InviteListMembers', [eventId, listId, senderId], 1)
		const createdCount = outParams.out0
		if (createdCount > 0) {
			const event = await this.db.callProcedure('sp_GetEventById', [eventId])
			const sender = await this.userService.getUserById(senderId)
			if (event.results.length > 0 && sender) {
				const eventTitle = event.results[0].title
				const senderName = sender.fullName
				const { results: members } = await this.db.callProcedure('sp_GetDistributionListMembers', [listId])
				const { results: invitations } = await this.db.callProcedure('sp_GetInvitationsByEvent', [eventId])
				const memberIds = members.map((m: any) => m.id)
				const newInvitations = invitations.filter((inv: any) => memberIds.includes(inv.userId) && inv.status === 'PENDING')
				for (const invitation of newInvitations) {
					const member = members.find((m: any) => m.id === invitation.userId)
					if (member?.email) {
						await this.emailService.sendInvitationEmail(member.email, eventTitle, senderName, invitation.id)
					}
				}
			}
		}
		return createdCount
	}
	async respondToInvitation(id: number, status: InvitationStatus, userId: number): Promise<boolean> {
		const { outParams } = await this.db.executeWithOutParams('sp_RespondToInvitation', [id, status, userId], 1)
		return outParams.out0 === 1
	}
	async deleteInvitation(id: number, deletedByUserId: number): Promise<boolean> {
		const { outParams } = await this.db.executeWithOutParams('sp_DeleteInvitation', [id, deletedByUserId], 1)
		return outParams.out0 === 1
	}
	async getInvitationsByUser(userId: number): Promise<any[]> {
		const { results } = await this.db.callProcedure('sp_GetInvitationsByUser', [userId])
		const invitations = results as any[]
		return invitations.map(invitation => {
			return {
				...invitation,
				event: {
					id: invitation.eventId,
					title: invitation.eventTitle,
					description: invitation.eventDescription,
					startTime: invitation.eventStartTime,
					endTime: invitation.eventEndTime,
				},
			}
		})
	}
	async getInvitationsByEvent(eventId: number): Promise<any[]> {
		const { results } = await this.db.callProcedure('sp_GetInvitationsByEvent', [eventId])
		return results as any[]
	}
	async getPendingInvitationsByUser(userId: number): Promise<any[]> {
		const { results } = await this.db.callProcedure('sp_GetPendingInvitationsByUser', [userId])
		return results as any[]
	}
}
class AuthController {
	private authService: AuthService
	constructor() {
		this.authService = new AuthService()
	}
	async register(c: Context): Promise<any> {
		const body = await c.req.json()
		const { email, fullName, password, role } = body
		const result = await this.authService.register(email, fullName, password, role)
		return c.json({ success: true, ...result })
	}
	async login(c: Context): Promise<any> {
		const body = await c.req.json()
		const { email, password } = body
		const result = await this.authService.login(email, password)
		return c.json({ success: true, ...result })
	}
	async changePassword(c: Context): Promise<any> {
		const body = await c.req.json()
		const { currentPassword, newPassword } = body
		const user = c.get('user')
		const result = await this.authService.changePassword(user.userId, currentPassword, newPassword)
		return c.json({ success: result })
	}
}
class UserController {
	private userService: UserService
	constructor() {
		this.userService = new UserService()
	}
	async getCurrentUser(c: Context): Promise<any> {
		const user = c.get('user')
		const userData = await this.userService.getUserById(user.userId)
		if (!userData) return c.json({ success: false, error: 'User not found' }, 404)
		return c.json({ success: true, user: userData })
	}
	async updateUser(c: Context): Promise<any> {
		const body = await c.req.json()
		const { fullName } = body
		const user = c.get('user')
		const result = await this.userService.updateUser(user.userId, { fullName })
		return c.json({ success: result })
	}
	async getAllUsers(c: Context): Promise<any> {
		const query = c.req.query('role')
		let users: any[] = []
		if (!query) users = await this.userService.getAllUsers()
		else {
			users = await this.userService.getAllUsers()
			users = users.filter(user => user.role === query)
		}
		return c.json({ success: true, users })
	}
	async promoteToModerator(c: Context): Promise<any> {
		const userId = Number(c.req.param('id'))
		const promoter = c.get('user')
		const result = await this.userService.promoteToModerator(userId, promoter.userId)
		return c.json({ success: result })
	}
	async demoteToUser(c: Context): Promise<any> {
		const userId = Number(c.req.param('id'))
		const demoter = c.get('user')
		const result = await this.userService.demoteToUser(userId, demoter.userId)
		return c.json({ success: result })
	}
}
class LocationController {
	private locationService: LocationService
	constructor() {
		this.locationService = new LocationService()
	}
	async getLocationById(c: Context): Promise<any> {
		const id = Number(c.req.param('id'))
		const location = await this.locationService.getLocationById(id)
		if (!location) return c.json({ success: false, error: 'Location not found' }, 404)
		return c.json({ success: true, location })
	}
	async createLocation(c: Context): Promise<any> {
		// TODO
	}
	async updateLocation(c: Context): Promise<any> {
		const id = Number(c.req.param('id'))
		const body = await c.req.json()
		const { name, address, mapsUrl } = body
		const result = await this.locationService.updateLocation(id, { name, address, mapsUrl })
		return c.json({ success: result })
	}
	async deleteLocation(c: Context): Promise<any> {
		const id = Number(c.req.param('id'))
		const result = await this.locationService.deleteLocation(id)
		return c.json({ success: result })
	}
	async getAllLocations(c: Context): Promise<any> {
		const locations = await this.locationService.getAllLocations()
		return c.json({ success: true, locations })
	}
}
class EventController {
	private eventService: EventService
	constructor() {
		this.eventService = new EventService()
	}
	async getEventById(c: Context): Promise<any> {
		const id = Number(c.req.param('id'))
		const event = await this.eventService.getEventById(id)
		if (!event) return c.json({ success: false, error: 'Event not found' }, 404)
		return c.json({ success: true, event })
	}
	async createEvent(c: Context): Promise<any> {
		const body = await c.req.json()
		const user = c.get('user')
		const {
			title,
			description,
			locationId,
			startTime,
			endTime,
			isPublished,
			capacity,
			requiresCheckout,
			checkoutToleranceMinutes,
			isRecurring,
			recurrencePattern,
		} = body
		const eventId = await this.eventService.createEvent({
			title,
			description,
			locationId,
			startTime: new Date(startTime),
			endTime: new Date(endTime),
			isPublished,
			capacity,
			requiresCheckout,
			checkoutToleranceMinutes,
			organizerId: user.userId,
			isRecurring,
			recurrencePattern,
		})
		return c.json({ success: true, id: eventId })
	}
	async updateEvent(c: Context): Promise<any> {
		// TODO
	}
	async deleteEvent(c: Context): Promise<any> {
		const id = Number(c.req.param('id'))
		const user = c.get('user')
		const result = await this.eventService.deleteEvent(id, user.userId)
		return c.json({ success: result })
	}
	async getEventsByOrganizer(c: Context): Promise<any> {
		const user = c.get('user')
		const status = c.req.query('status') ?? EventStatus.UPCOMING
		const events = await this.eventService.getEventsByOrganizer(user.userId, status)
		return c.json({ success: true, events })
	}
	async getUpcomingEvents(c: Context): Promise<any> {
		const events = await this.eventService.getUpcomingEvents()
		return c.json({ success: true, events })
	}
	async getInProgressEvents(c: Context): Promise<any> {
		const events = await this.eventService.getInProgressEvents()
		return c.json({ success: true, events })
	}
	async getUserEvents(c: Context): Promise<any> {
		const user = c.get('user')
		const events = await this.eventService.getUserEvents(user.userId)
		return c.json({ success: true, events })
	}
	async publishEvent(c: Context): Promise<any> {
		const id = Number(c.req.param('id'))
		const user = c.get('user')
		const result = await this.eventService.publishEvent(id, user.userId)
		return c.json({ success: result })
	}
	async cancelEvent(c: Context): Promise<any> {
		const id = Number(c.req.param('id'))
		const user = c.get('user')
		const result = await this.eventService.cancelEvent(id, user.userId)
		return c.json({ success: result })
	}
}
class AttendanceController {
	private attendanceService: AttendanceService
	constructor() {
		this.attendanceService = new AttendanceService()
	}
	async getAttendancesByEvent(c: Context): Promise<any> {
		const eventId = Number(c.req.param('id'))
		const attendances = await this.attendanceService.getAttendancesByEvent(eventId)
		return c.json({ success: true, attendances })
	}
	async getAttendancesByUser(c: Context): Promise<any> {
		const user = c.get('user')
		const attendances = await this.attendanceService.getAttendancesByUser(user.userId)
		return c.json({ success: true, attendances })
	}
	async getAttendanceStats(c: Context): Promise<any> {
		const eventId = Number(c.req.param('id'))
		const stats = await this.attendanceService.getAttendanceStats(eventId)
		return c.json({ success: true, stats })
	}
	async processQR(c: Context): Promise<any> {
		const body = await c.req.json()
		const { token } = body
		const user = c.get('user')
		const result = await this.attendanceService.processQRToken(token, user.userId)
		return c.json(result)
	}
	async generateCheckinQR(c: Context): Promise<any> {
		const eventId = Number(c.req.param('id'))
		const user = c.get('user')
		const token = await this.attendanceService.generateCheckinQR(eventId, user.userId)
		return c.json({ success: true, token })
	}
	async generateCheckoutQR(c: Context): Promise<any> {
		const eventId = Number(c.req.param('id'))
		const user = c.get('user')
		const token = await this.attendanceService.generateCheckoutQR(eventId, user.userId)
		return c.json({ success: true, token })
	}
}
class DistributionListController {
	private distributionListService: DistributionListService
	constructor() {
		this.distributionListService = new DistributionListService()
	}
	async getListById(c: Context): Promise<any> {
		const id = Number(c.req.param('id'))
		const list = await this.distributionListService.getListById(id)
		if (!list) return c.json({ success: false, error: 'Distribution list not found' }, 404)
		return c.json({ success: true, list })
	}
	async createList(c: Context): Promise<any> {
		const body = await c.req.json()
		const { name, description } = body
		const user = c.get('user')
		const listId = await this.distributionListService.createList(name, description, user.userId)
		return c.json({ success: true, id: listId })
	}
	async updateList(c: Context): Promise<any> {
		const id = Number(c.req.param('id'))
		const body = await c.req.json()
		const { name, description } = body
		const user = c.get('user')
		const result = await this.distributionListService.updateList(id, { name, description }, user.userId)
		return c.json({ success: result })
	}
	async deleteList(c: Context): Promise<any> {
		const id = Number(c.req.param('id'))
		const user = c.get('user')
		const result = await this.distributionListService.deleteList(id, user.userId)
		return c.json({ success: result })
	}
	async getListsByOrganizer(c: Context): Promise<any> {
		const user = c.get('user')
		const lists = await this.distributionListService.getListsByOrganizer(user.userId)
		return c.json({ success: true, lists })
	}
	async addMemberToList(c: Context): Promise<any> {
		const listId = Number(c.req.param('id'))
		const body = await c.req.json()
		const { userId } = body
		const user = c.get('user')
		const result = await this.distributionListService.addMemberToList(listId, userId, user.userId)
		return c.json({ success: result })
	}

	async addMultipleMembersToList(c: Context): Promise<any> {
		const listId = Number(c.req.param('id'))
		const body = await c.req.json()
		const { userIds } = body
		const user = c.get('user')
		const result = await this.distributionListService.addMultipleMembersToList(listId, userIds, user.userId)
		return c.json({ success: result })
	}

	async removeMemberFromList(c: Context): Promise<any> {
		const listId = Number(c.req.param('id'))
		const userId = Number(c.req.param('userId'))
		const user = c.get('user')
		const result = await this.distributionListService.removeMemberFromList(listId, userId, user.userId)
		return c.json({ success: result })
	}
	async getListMembers(c: Context): Promise<any> {
		const listId = Number(c.req.param('id'))
		const members = await this.distributionListService.getListMembers(listId)
		return c.json({ success: true, members })
	}
}
class InvitationController {
	private invitationService: InvitationService
	constructor() {
		this.invitationService = new InvitationService()
	}
	async getInvitationById(c: Context): Promise<any> {
		const id = Number(c.req.param('id'))
		const invitation = await this.invitationService.getInvitationById(id)
		if (!invitation) return c.json({ success: false, error: 'Invitation not found' }, 404)
		return c.json({ success: true, invitation })
	}
	async createInvitation(c: Context): Promise<any> {
		const body = await c.req.json()
		const { eventId, userId } = body
		const sender = c.get('user')
		const invitationId = await this.invitationService.createInvitation(eventId, userId, sender.userId)
		return c.json({ success: true, id: invitationId })
	}
	async bulkCreateInvitations(c: Context): Promise<any> {
		const body = await c.req.json()
		const { eventId, userIds } = body
		const sender = c.get('user')
		const createdCount = await this.invitationService.bulkCreateInvitations(eventId, userIds, sender.userId)
		return c.json({ success: true, count: createdCount })
	}
	async inviteList(c: Context): Promise<any> {
		const body = await c.req.json()
		const { eventId, listId } = body
		const sender = c.get('user')
		const createdCount = await this.invitationService.inviteList(eventId, listId, sender.userId)
		return c.json({ success: true, count: createdCount })
	}
	async respondToInvitation(c: Context): Promise<any> {
		const id = Number(c.req.param('id'))
		const body = await c.req.json()
		const { status } = body
		const user = c.get('user')
		const result = await this.invitationService.respondToInvitation(id, status, user.userId)
		return c.json({ success: result })
	}
	async deleteInvitation(c: Context): Promise<any> {
		const id = Number(c.req.param('id'))
		const user = c.get('user')
		const result = await this.invitationService.deleteInvitation(id, user.userId)
		return c.json({ success: result })
	}
	async getInvitationsByUser(c: Context): Promise<any> {
		const user = c.get('user')
		const invitations = await this.invitationService.getInvitationsByUser(user.userId)
		return c.json({ success: true, invitations })
	}
	async getInvitationsByEvent(c: Context): Promise<any> {
		const eventId = Number(c.req.param('id'))
		const invitations = await this.invitationService.getInvitationsByEvent(eventId)
		return c.json({ success: true, invitations })
	}
	async getPendingInvitationsByUser(c: Context): Promise<any> {
		const user = c.get('user')
		const invitations = await this.invitationService.getPendingInvitationsByUser(user.userId)
		return c.json({ success: true, invitations })
	}
}

const $auth = new AuthController()
const $user = new UserController()
const $location = new LocationController()
const $event = new EventController()
const $attendance = new AttendanceController()
const $distributionList = new DistributionListController()
const $invitation = new InvitationController()

const app = new Hono()

app.use('*', logger())

app.get('/api/health', c => {
	return c.json({
		status: 'ok',
		version: '1.0.0',
		timestamp: new Date().toISOString(),
	})
})

const authService = new AuthService()

export const authenticate: MiddlewareHandler = async (c, next) => {
	try {
		const authHeader = c.req.header('Authorization')
		if (!authHeader) {
			return c.json({ success: false, error: 'Authentication required' }, 401)
		}

		const token = authHeader.split(' ')[1]
		if (!token) {
			return c.json({ success: false, error: 'Invalid token format' }, 401)
		}

		const payload = await authService.verifyToken(token)
		if (!payload || !payload.userId) {
			return c.json({ success: false, error: 'Invalid token' }, 401)
		}

		c.set('user', payload)
		await next()
	} catch (error: any) {
		return c.json({ success: false, error: error.message || 'Authentication failed' }, 401)
	}
}

export const authorize = (roles: UserRole[]): MiddlewareHandler => {
	return async (c, next) => {
		const user = c.get('user')
		if (!user || !user.role) {
			return c.json({ success: false, error: 'Authentication required' }, 401)
		}

		if (!roles.includes(user.role)) {
			return c.json({ success: false, error: 'Insufficient permissions' }, 403)
		}

		await next()
	}
}

export const authMiddleware = {
	user: authenticate,
	moderator: [authenticate, authorize([UserRole.MODERATOR, UserRole.ORGANIZER])],
	organizer: [authenticate, authorize([UserRole.ORGANIZER])],
}

const AUTH = new Hono()
	.post('/register', zValidator('json', Validators.userSchema), c => $auth.register(c))
	.post('/login', zValidator('json', Validators.loginSchema), c => $auth.login(c))
	.get('/check-token', authenticate, c => c.json({ success: true }))
	.post('/change-password', authenticate, c => $auth.changePassword(c))

const USERS = new Hono()
	.get('/me', authenticate, c => $user.getCurrentUser(c))
	.put('/me', authenticate, c => $user.updateUser(c))
	.get('/', ...authMiddleware.organizer, c => $user.getAllUsers(c))
	.post('/:id/promote', ...authMiddleware.organizer, c => $user.promoteToModerator(c))
	.post('/:id/demote', ...authMiddleware.organizer, c => $user.demoteToUser(c))

const LOCATIONS = new Hono()
	.post('/', ...authMiddleware.organizer, c => $location.createLocation(c))
	.get('/', authenticate, c => $location.getAllLocations(c))
	.get('/:id', authenticate, c => $location.getLocationById(c))
	.put('/:id', ...authMiddleware.organizer, c => $location.updateLocation(c))
	.delete('/:id', ...authMiddleware.organizer, c => $location.deleteLocation(c))

const EVENTS = new Hono()
	.post('/', ...authMiddleware.organizer, c => $event.createEvent(c))
	.get('/organizer', ...authMiddleware.organizer, c => $event.getEventsByOrganizer(c))
	.get('/upcoming', authenticate, c => $event.getUpcomingEvents(c))
	.get('/in-progress', authenticate, c => $event.getInProgressEvents(c))
	.get('/user', authenticate, c => $event.getUserEvents(c))
	.get('/:id', authenticate, c => $event.getEventById(c))
	.put('/:id', ...authMiddleware.organizer, c => $event.updateEvent(c))
	.delete('/:id', ...authMiddleware.organizer, c => $event.deleteEvent(c))
	.post('/:id/publish', ...authMiddleware.organizer, c => $event.publishEvent(c))
	.post('/:id/cancel', ...authMiddleware.organizer, c => $event.cancelEvent(c))
	.get('/:id/attendances', authenticate, c => $attendance.getAttendancesByEvent(c))
	.get('/:id/stats', authenticate, c => $attendance.getAttendanceStats(c))
	.get('/:id/invitations', authenticate, c => $invitation.getInvitationsByEvent(c))
	.get('/:id/checkin-qr', authenticate, c => $attendance.generateCheckinQR(c))
	.get('/:id/checkout-qr', authenticate, c => $attendance.generateCheckoutQR(c))

const ATTENDANCES = new Hono()
	.get('/user', authenticate, c => $attendance.getAttendancesByUser(c))
	.post('/process-qr', ...authMiddleware.moderator, c => $attendance.processQR(c))

const LISTS = new Hono()
	.post('/', ...authMiddleware.organizer, c => $distributionList.createList(c))
	.get('/', ...authMiddleware.organizer, c => $distributionList.getListsByOrganizer(c))
	.put('/:id', ...authMiddleware.organizer, c => $distributionList.updateList(c))
	.delete('/:id', ...authMiddleware.organizer, c => $distributionList.deleteList(c))
	.get('/:id', authenticate, c => $distributionList.getListById(c))
	.post('/:id/members', ...authMiddleware.organizer, c => $distributionList.addMultipleMembersToList(c))
	.delete('/:id/members/:userId', ...authMiddleware.organizer, c => $distributionList.removeMemberFromList(c))
	.get('/:id/members', authenticate, c => $distributionList.getListMembers(c))

const INVITATIONS = new Hono()
	.post('/', ...authMiddleware.organizer, c => $invitation.createInvitation(c))
	.post('/bulk', ...authMiddleware.organizer, c => $invitation.bulkCreateInvitations(c))
	.post('/list', ...authMiddleware.organizer, c => $invitation.inviteList(c))
	.get('/user', authenticate, async c => await $invitation.getInvitationsByUser(c))
	.post('/:id/respond', authenticate, c => $invitation.respondToInvitation(c))
	.get('/:id', authenticate, async c => await $invitation.getInvitationById(c))
	.delete('/:id', ...authMiddleware.organizer, c => $invitation.deleteInvitation(c))
	.get('/user/pending', authenticate, async c => await $invitation.getPendingInvitationsByUser(c))

app.route('/api/invitations', INVITATIONS)
app.route('/api/lists', LISTS)
app.route('/api/attendances', ATTENDANCES)
app.route('/api/events', EVENTS)
app.route('/api/locations', LOCATIONS)
app.route('/api/users', USERS)
app.route('/api/auth', AUTH)

app.notFound(c => {
	return c.json({ error: 'Not found' }, 404)
})
app.onError((err, c) => {
	console.error(err)
	return c.json({ error: err.message }, 500)
})

export default {
	fetch: app.fetch,
	port: 5000,
}
