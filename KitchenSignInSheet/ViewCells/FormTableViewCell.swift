//
//  FormTableViewCell.swift
//  Coop
//
//  Created by Sirius on 3/15/22.
//

import UIKit


protocol FormTableViewCellDelegate: AnyObject {
    func formtableViewCell(_ cell: FormTableViewCell, didUpdateField updateModel: EditProfileFormModel)
}

class FormTableViewCell: UITableViewCell, UITextFieldDelegate {

    static let identifier = "FormTableViewCell"
    private let formLabel: UILabel={
       let label = UILabel()
        label.textColor = .label
        label.numberOfLines = 1
        //label.textAlignment = .right
        return label
    }()
    
    private var model: EditProfileFormModel?
    
    public weak var delegate: FormTableViewCellDelegate?
    
    public let field: UITextField = {
       let field = UITextField()
        field.returnKeyType = .done
        field.textAlignment = .center
        return field
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?){
        super.init(style: style, reuseIdentifier: reuseIdentifier )
        
        clipsToBounds = true
        contentView.addSubview(formLabel)
        contentView.addSubview(field)
        field.delegate = self
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(with model: EditProfileFormModel){
        self.model = model
        formLabel.text = model.label
        
        if let value = model.value{
            field.text = value
        }else{
            field.placeholder = model.placeholder
        }
        field.textColor = .black
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        formLabel.text = nil
        field.placeholder = nil
        field.text = nil
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        formLabel.frame = CGRect(x: 15, y: 0, width: contentView.width / 2, height: contentView.height)
        
        field.frame = CGRect(x: formLabel.right + 5, y: 0, width: contentView.width - 35 - formLabel.width, height: contentView.height)
    }
    
    
    /// MARK: - Field
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        model?.value = textField.text
        textField.resignFirstResponder()
        guard let model = model else{
            return true
        }
        delegate?.formtableViewCell(self, didUpdateField: model)
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        model?.value = textField.text
        textField.textColor = .green
        if let model = model{
            delegate?.formtableViewCell(self, didUpdateField: model)
        }
    }
}
