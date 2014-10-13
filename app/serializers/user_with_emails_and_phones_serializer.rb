class UserWithEmailsAndPhonesSerializer < UserSerializer
  attributes :hashed_emails, :hashed_phone_numbers

  def hashed_emails
    object.emails.map(&:hashed_email)
  end

  def hashed_phone_numbers
    object.phones.select(&:verified?).map(&:hashed_number)
  end
end
